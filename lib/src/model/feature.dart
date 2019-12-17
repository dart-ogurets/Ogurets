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
    bool matchedFeatureTags = state.tagsMatch(tags);
    bool negativeTagsMatch = state.negativeTagsMatch(tags);

    if (!negativeTagsMatch && (matchedFeatureTags || tags.isEmpty)) {
      // a feature can have no tags
      state.fmt.feature(featureStatus);

      bool isFirstScenario = true;
      for (Scenario scenario in scenarios) {
        _log.fine(
            "Requested tags: $state.runTags.  Scenario is tagged with: ${scenario.tags}. Matched feature? $matchedFeatureTags");
        // we matched the scenario name OR there is no scenario name, we don't match the negatives and we either match the feature or the scenario tags
        if ((state.scenarioToRun == scenario.name) ||
            (state.scenarioToRun == null && !state.negativeTagsMatch(scenario.tags) && ((matchedFeatureTags) || state.tagsMatch(scenario.tags))))
        {
          _log.fine("Executing Scenario: $scenario");

          scenario.background = background;
          List<ScenarioStatus> scenarioStatuses =
              await scenario.execute(state, isFirstOfFeature: isFirstScenario);

          scenarioStatuses.forEach((scenarioStatus) {
            if (scenarioStatus.failed ||
                (state.failOnMissingSteps &&
                    scenarioStatus.undefinedSteps.isNotEmpty)) {
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

  /// Converts to printable format
  String toString() {
    return "$name ${tags == null ? "" : tags}\n $background \n$scenarios";
  }
}
