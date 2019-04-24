part of dherkin_core3;

class Feature {
  String name;
  List<String> tags;

  Scenario background;
  List<Scenario> scenarios = [];

  Location location;

  Feature(this.name, this.location);

  Future<FeatureStatus> execute(DherkinState state, {List<String> runTags, bool debug: false}) async {
    if (runTags == null) runTags = [];
    FeatureStatus featureStatus = new FeatureStatus(state.fmt)..feature = this;

    if (state.tagsMatch(tags, runTags)) {
      state.fmt.feature(featureStatus);

      bool isFirstScenario = true;
      for (Scenario scenario in scenarios) {
        _log.fine("Requested tags: $runTags.  Scenario is tagged with: ${scenario.tags}");
        if (state.tagsMatch(scenario.tags, runTags) && (state.scenarioToRun == null || (state.scenarioToRun == scenario.name))) {
          _log.fine("Executing Scenario: $scenario");

          DherkinScenarioSession scenarioSession = new DherkinScenarioSession({}..addAll(state.existingInstances));

          await state.runBeforeTags(scenario.tags, scenarioSession);

          try {
            scenario.background = background;
            ScenarioStatus scenarioStatus = await scenario.execute(state, scenarioSession, isFirstOfFeature: isFirstScenario);

            if (scenarioStatus.failed || (state.failOnMissingSteps && scenarioStatus.undefinedSteps.length > 0)) {
              featureStatus.failedScenarios.add(scenarioStatus);
            } else {
              featureStatus.passedScenarios.add(scenarioStatus);
            }
          } finally { // make sure we run the after tags
            await state.runAfterTags(scenario.tags, scenarioSession);
          }

        } else {
          _log.fine("Skipping Scenario: $scenario");
        }
      }

      state.fmt.done(featureStatus);
      return featureStatus;
    } else {
      _log.info("Skipping feature $name due to tags not matching");
      featureStatus.skipped = true;

      return featureStatus;
    }
  }

  /**
   * Converts to printable format
   */
  String toString() {
    return "$name ${tags == null ? "" : tags}\n $background \n$scenarios";
  }
}
