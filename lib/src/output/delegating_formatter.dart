part of ogurets_core3;

class DelegatingFormatter implements Formatter {
  final List<Formatter> formatters;

  DelegatingFormatter(this.formatters);

  @override
  void background(Background background) {
    formatters.forEach((f) => f.background(background));
  }

  @override
  void close() {
    formatters.forEach((f) => f.close());
  }

  @override
  void done(Object status) {
    formatters.forEach((f) => f.done(status));
  }

  @override
  void endOfScenarioLifeCycle(Scenario endScenario) {
    formatters.forEach((f) => f.endOfScenarioLifeCycle(endScenario));
  }

  @override
  void eof(RunStatus status) {
    formatters.forEach((f) => f.eof(status));
  }

  @override
  void examples(GherkinTable examples) {
    formatters.forEach((f) => f.examples(examples));
  }

  @override
  void feature(FeatureStatus featureStatus) {
    formatters.forEach((f) => f.feature(featureStatus));
  }

  @override
  void scenario(ScenarioStatus scenario) {
    formatters.forEach((f) => f.scenario(scenario));
  }

  @override
  void startOfScenarioLifeCycle(Scenario startScenario) {
    formatters.forEach((f) => f.startOfScenarioLifeCycle(startScenario));
  }

  @override
  void step(StepStatus step) {
    formatters.forEach((f) => f.step(step));
  }

  @override
  void syntaxError(
      String var1, String var2, List<String> var3, String var4, int var5) {
    formatters.forEach((f) => f.syntaxError(var1, var2, var3, var4, var5));
  }
}