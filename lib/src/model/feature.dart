part of ogurets_core3;

class Feature {
  String name;
  List<String> tags;

  Scenario background;
  List<Scenario> scenarios = [];

  Location location;

  Feature(this.name, this.location);

  Future<FeatureStatus> execute(OguretsState state, {bool debug: false}) async {
    FeatureStatus featureStatus = new FeatureStatus(state.fmt)..feature = this;
    bool matchedFeatureTags = state.tagsMatch(tags);
    bool negativeTagsMatch = state.negativeTagsMatch(tags);

    print("matched $matchedFeatureTags neg $negativeTagsMatch");
    if (!negativeTagsMatch && (matchedFeatureTags || tags.isEmpty)) { // a feature can have no tags
      state.fmt.feature(featureStatus);

      bool isFirstScenario = true;
      for (Scenario scenario in scenarios) {
        _log.fine("Requested tags: $state.runTags.  Scenario is tagged with: ${scenario.tags}. Matched feature? $matchedFeatureTags");
        print("Requested tags: $state.runTags.  Scenario is tagged with: ${scenario.tags}. Matched feature? $matchedFeatureTags");
        if (!state.negativeTagsMatch(scenario.tags) &&
            ((matchedFeatureTags) || (state.tagsMatch(scenario.tags) && (state.scenarioToRun == null || (state.scenarioToRun == scenario.name))))) {
          _log.fine("Executing Scenario: $scenario");

          scenario.background = background;
          List<ScenarioStatus> scenarioStatuses = await scenario.execute(state, isFirstOfFeature: isFirstScenario);

          scenarioStatuses.forEach((scenarioStatus) {
            if (scenarioStatus.failed || (state.failOnMissingSteps && scenarioStatus.undefinedSteps.length > 0)) {
              featureStatus.failedScenarios.add(scenarioStatus);
            } else {
              featureStatus.passedScenarios.add(scenarioStatus);
            }
          });
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
