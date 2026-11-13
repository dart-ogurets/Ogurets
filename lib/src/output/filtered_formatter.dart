part of '../../ogurets.dart';

/// Formatter that will filter out certain types of messages.
/// Useful for reducing the logs when running large amounts of features.
class FilteredFormatter implements Formatter {
  final Set<Formatter> formatters;

  final Set<Filter> filters;

  FilteredFormatter(this.formatters, this.filters);

  @override
  void background(GherkinBackground background) {
    if (!filters.contains(Filter.scenarios) &&
        !filters.contains(Filter.backgrounds)) {
      for (var f in formatters) {
        f.background(background);
      }
    }
  }

  @override
  void close() {
    for (var f in formatters) {
      f.close();
    }
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
  void endOfScenarioLifeCycle(GherkinScenario endScenario) {
    if (!filters.contains(Filter.scenarios)) {
      for (var f in formatters) {
        f.endOfScenarioLifeCycle(endScenario);
      }
    }
  }

  @override
  void eof(RunStatus status) {
    for (var f in formatters) {
      f.eof(status);
    }
  }

  @override
  void examples(GherkinTable examples) {
    for (var f in formatters) {
      f.examples(examples);
    }
  }

  @override
  void feature(FeatureStatus featureStatus) {
    if (!filters.contains(Filter.features)) {
      for (var f in formatters) {
        f.feature(featureStatus);
      }
    }
  }

  @override
  void scenario(ScenarioStatus scenario) {
    if (!filters.contains(Filter.scenarios)) {
      for (var f in formatters) {
        f.scenario(scenario);
      }
    }
  }

  @override
  void startOfScenarioLifeCycle(GherkinScenario startScenario) {
    if (!filters.contains(Filter.scenarios)) {
      for (var f in formatters) {
        f.startOfScenarioLifeCycle(startScenario);
      }
    }
  }

  @override
  void step(StepStatus step) {
    if (!filters.contains(Filter.steps)) {
      for (var f in formatters) {
        f.step(step);
      }
    }
  }

  @override
  void syntaxError(
    String var1,
    String var2,
    List<String> var3,
    String var4,
    int var5,
  ) {
    for (var f in formatters) {
      f.syntaxError(var1, var2, var3, var4, var5);
    }
  }
}

/// Values used for filtering out certain messages.
enum Filter { steps, scenarios, backgrounds, features }
