part of dherkin_core;

class Feature {

  String name;
  List<String> tags;

  Scenario background;
  List<Scenario> scenarios = [];

  Location location;

  Feature(this.name, this.location);

  Future<FeatureStatus> execute(Map<RegExp, Function> stepRunners,
                                { List<String> runTags, Worker worker, bool debug: false }) {
    if (runTags == null) runTags = [];
    FeatureStatus featureStatus = new FeatureStatus()
      ..feature = this;

    if (_tagsMatch(tags, runTags)) {
      featureStatus.buffer.write("\nFeature: $name");
      featureStatus.buffer.writeln("$location", color: 'gray');

      var completer = new Completer();
      var results = [];
      bool isFirstScenario = true;
      Future.forEach(scenarios, (Scenario scenario) {
        _log.debug("Requested tags: $runTags.  Scenario is tagged with: ${scenario.tags}");
        if (_tagsMatch(scenario.tags, runTags)) {
          _log.debug("Executing Scenario: $scenario");

          scenario.background = background;

          Future scenarioFuture;
          if (worker != null) {
            // the Task will re-fetch the stepRunners, as we can't send them here.
            scenarioFuture = worker.handle(new ScenarioExecutionTask(scenario, isFirst: isFirstScenario, debug: debug));
          } else {
            scenarioFuture = scenario.execute(stepRunners, isFirstOfFeature: isFirstScenario);
          }

          isFirstScenario = false;

          scenarioFuture.then((ScenarioStatus scenarioStatus) {

            featureStatus.buffer.merge(scenarioStatus.buffer);

            if (scenarioStatus.failed) {
              featureStatus.failedScenarios.add(scenarioStatus);
            } else {
              featureStatus.passedScenarios.add(scenarioStatus);
            }
          }).catchError((e, s) {
            _log.debug("ERROR $e \n $s");
          });

          results.add(scenarioFuture);
        } else {
          _log.debug("Skipping Scenario: $scenario");
        }
      }).whenComplete(() {
        Future.wait(results).whenComplete(() {
          featureStatus.buffer.writeln("-------------------");
          featureStatus.buffer.writeln("Scenarios passed: ${featureStatus.passedScenariosCount}", color: 'green');

          if (featureStatus.failedScenariosCount > 0) {
            featureStatus.buffer.writeln("Scenarios failed: ${featureStatus.failedScenariosCount}", color: 'red');
          }

          completer.complete(featureStatus);
        });
      });

      return completer.future;
    } else {
      _log.info("Skipping feature $name due to tags not matching");
      featureStatus.skipped = true;

      return new Future.value(featureStatus);
    }
  }

  /**
   * Converts to printable format
   */
  String toString() {
    return "$name ${tags == null ? "" : tags}\n $background \n$scenarios";
  }
}