part of dherkin_core3;

class Feature {
  String name;
  List<String> tags;

  Scenario background;
  List<Scenario> scenarios = [];

  Location location;

  Feature(this.name, this.location);

  Future<FeatureStatus> execute(DherkinState state, {List<String> runTags, bool debug: false}) async {
    Map<RegExp, Function> stepRunners = state.stepRunners;
    if (runTags == null) runTags = [];
    FeatureStatus featureStatus = new FeatureStatus()..feature = this;

    if (_tagsMatch(tags, runTags)) {
      featureStatus.buffer.write("\nFeature: $name");
      featureStatus.buffer.writeln("$location", color: 'gray');

      bool isFirstScenario = true;
      for (Scenario scenario in scenarios) {
        _log.fine("Requested tags: $runTags.  Scenario is tagged with: ${scenario.tags}");
        if (_tagsMatch(scenario.tags, runTags) && (state.scenarioToRun == null || (state.scenarioToRun == scenario.name))) {
          _log.fine("Executing Scenario: $scenario");

          Map<Type, InstanceMirror> instances = {}..addAll(state.existingInstances);

          scenario.background = background;
          ScenarioStatus scenarioStatus = await scenario.execute(stepRunners, instances, isFirstOfFeature: isFirstScenario);
          isFirstScenario = false;
          featureStatus.buffer.merge(scenarioStatus.buffer);

          if (scenarioStatus.failed || (state.failOnMissingSteps && scenarioStatus.undefinedSteps.length > 0)) {
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
