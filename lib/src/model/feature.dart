part of dherkin_core;

class Feature {
  String name;
  List<String> tags;

  Scenario background;
  List<Scenario> scenarios = [];

  Location location;

  Feature(this.name, this.location);

  Future<FeatureStatus> execute(Map<RegExp, Function> stepRunners, {List<String> runTags, bool debug: false}) async {
    if (runTags == null) runTags = [];
    FeatureStatus featureStatus = new FeatureStatus()..feature = this;

    if (_tagsMatch(tags, runTags)) {
      featureStatus.buffer.write("\nFeature: $name");
      featureStatus.buffer.writeln("$location", color: 'gray');

      bool isFirstScenario = true;
      for (Scenario scenario in scenarios) {
        _log.fine("Requested tags: $runTags.  Scenario is tagged with: ${scenario.tags}");
        if (_tagsMatch(scenario.tags, runTags)) {
          _log.fine("Executing Scenario: $scenario");

          scenario.background = background;
          ScenarioStatus scenarioStatus = await scenario.execute(stepRunners, isFirstOfFeature: isFirstScenario);
          isFirstScenario = false;
          featureStatus.buffer.merge(scenarioStatus.buffer);

          if (scenarioStatus.failed) {
            featureStatus.failedScenarios.add(scenarioStatus);
          } else {
            featureStatus.passedScenarios.add(scenarioStatus);
          }
        } else {
          _log.fine("Skipping Scenario: $scenario");
        }
      }
      featureStatus.buffer.writeln("-------------------");
      featureStatus.buffer.writeln("Scenarios passed: ${featureStatus.passedScenariosCount}", color: 'green');

      if (featureStatus.failedScenariosCount > 0) {
        featureStatus.buffer.writeln("Scenarios failed: ${featureStatus.failedScenariosCount}", color: 'red');
      }
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
