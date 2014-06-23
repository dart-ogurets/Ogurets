part of dherkin_core;


class GherkinParserTask implements Task {

  List<String> contents;
  String filePath;

  GherkinParserTask(List<String> this.contents, this.filePath);

  /**
   * Returns a Future to a fully populated Feature,
   * from the Gherkin feature statements in [contents],
   * which is a List of lines.
   */
  Future<Feature> execute() {
    return new Future.value(new GherkinParser().parse(contents, filePath: filePath));
  }
}


class ScenarioExecutionTask implements Task {

  Scenario scenario;
  bool debug;
  bool isFirst;

  ScenarioExecutionTask(this.scenario, {this.debug: false, this.isFirst: true});

  Future execute() {
    LoggerFactory.config[".*"].debugEnabled = debug;
    Completer c = new Completer();
    // We cannot have stepRunners as injected dependency, (object is closure),
    // so we re-seek them in this task.
    findStepRunners().then((stepRunners) {
      c.complete(scenario.execute(stepRunners, isFirstOfFeature: isFirst));
    });

    return c.future;
  }
}