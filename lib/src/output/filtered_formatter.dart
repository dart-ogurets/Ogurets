part of ogurets;

/// Formatter that will filter out certain types of messages.
/// Useful for reducing the logs when running large amounts of features.
class FilteredFormatter implements Formatter {

  final Set<Formatter> formatters;

  final Set<Filter> filters;

  FilteredFormatter(this.formatters, this.filters);

  @override
  void background(_Background background) {
    if (!filters.contains(Filter.scenarios) && !filters.contains(Filter.backgrounds)) {
      formatters.forEach((f) => f.background(background));
    }
  }

  @override
  void close() {
    formatters.forEach((f) => f.close());
  }

  @override
  void done(Object status) {
    if (status is FeatureStatus && filters.contains(Filter.features)) {
      return;
    }
    if (status is ScenarioStatus && filters.contains(Filter.scenarios)) {
      return;
    }
    if (status is StepStatus && filters.contains(Filter.steps)) {
      return;
    }
  }

  @override
  void endOfScenarioLifeCycle(_Scenario endScenario) {
    if (!filters.contains(Filter.scenarios)) {
      formatters.forEach((f) => f.endOfScenarioLifeCycle(endScenario));
    }
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
    if (!filters.contains(Filter.features)) {
      formatters.forEach((f) => f.feature(featureStatus));
    }
  }

  @override
  void scenario(ScenarioStatus scenario) {
    if (!filters.contains(Filter.scenarios)) {
      formatters.forEach((f) => f.scenario(scenario));
    }
  }

  @override
  void startOfScenarioLifeCycle(_Scenario startScenario) {
    if (!filters.contains(Filter.scenarios)) {
      formatters.forEach((f) => f.startOfScenarioLifeCycle(startScenario));
    }
  }

  @override
  void step(StepStatus step) {
    if (!filters.contains(Filter.steps)) {
      formatters.forEach((f) => f.step(step));
    }
  }

  @override
  void syntaxError(
      String var1, String var2, List<String> var3, String var4, int var5) {
    formatters.forEach((f) => f.syntaxError(var1, var2, var3, var4, var5));
  }
}

/// Values used for filtering out certain messages.
enum Filter {
  steps,
  scenarios,
  backgrounds,
  features,
}
