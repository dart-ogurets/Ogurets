part of ogurets_core3;

class Feature {
  String name;
  List<String> tags;

  Scenario background;
  List<Scenario> scenarios = [];

  Location location;

  Feature(this.name, this.location);

  Future<FeatureStatus> execute(OguretsState state, {bool debug = false}) async {
    FeatureStatus featureStatus = FeatureStatus(state.fmt)..feature = this;
    bool negativeTagsMatch = state.negativeTagsMatch(tags);

    if (!negativeTagsMatch) {
      state.fmt.feature(featureStatus);

      bool isFirstScenario = true;
      for (Scenario scenario in scenarios) {
        _log.fine("Requested tags: ${state.runTags}.  Scenario is tagged with: ${scenario.tags}.");

        // skip if it doesn't match the scenario name (when present), is excluded by the tags or doesn't match when tags are present
        // assumption is that if you specify a scenario, you wouldn't exclude it by tags
        var skip = state.scenarioToRun != null ? !(state.scenarioToRun == scenario.name) : (state.negativeTagsMatch(scenario.tags) || !state.tagsMatch(scenario.tags));

        if (!skip) {
          _log.fine("Executing scenario: ${scenario.name}");
        } else {
          _log.fine("Skipping scenario: ${scenario.name}");
        }

        scenario.background = background;
        List<ScenarioStatus> scenarioStatuses = await scenario.execute(state,
            isFirstOfFeature: isFirstScenario, skip: skip);

        scenarioStatuses.forEach((scenarioStatus) {
          if (scenarioStatus.failed ||
              (state.failOnMissingSteps &&
                  scenarioStatus.undefinedSteps.isNotEmpty)) {
            featureStatus.failedScenarios.add(scenarioStatus);
          } else if (scenarioStatus.skipped) {
            featureStatus.skippedScenarios.add(scenarioStatus);
          } else {
            featureStatus.passedScenarios.add(scenarioStatus);
          }
        });
      }

      state.fmt.done(featureStatus);

      return featureStatus;
    } else {
      _log.info("Skipping feature $name");
      featureStatus.skipped = true;

      return featureStatus;
    }
  }

  /// Converts to printable format
  String toString() {
    return "$name ${tags == null ? "" : tags}\n $background \n$scenarios";
  }
}
