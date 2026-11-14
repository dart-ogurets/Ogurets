part of '../../ogurets.dart';

class DelegatingFormatter implements Formatter {
  final Set<Formatter> formatters;

  DelegatingFormatter(this.formatters);

  @override
  void background(GherkinBackground background) {
    for (var f in formatters) {
      f.background(background);
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
    for (var f in formatters) {
      f.done(status);
    }
  }

  @override
  void endOfScenarioLifeCycle(GherkinScenario endScenario) {
    for (var f in formatters) {
      f.endOfScenarioLifeCycle(endScenario);
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
    for (var f in formatters) {
      f.feature(featureStatus);
    }
  }

  @override
  void scenario(ScenarioStatus scenario) {
    for (var f in formatters) {
      f.scenario(scenario);
    }
  }

  @override
  void startOfScenarioLifeCycle(GherkinScenario startScenario) {
    for (var f in formatters) {
      f.startOfScenarioLifeCycle(startScenario);
    }
  }

  @override
  void step(StepStatus step) {
    for (var f in formatters) {
      f.step(step);
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
