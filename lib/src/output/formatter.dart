part of ogurets_core3;

/// This is the interface you should implement if you want your own custom
/// formatter.
abstract class Formatter {
  void syntaxError(
      String var1, String var2, List<String> var3, String var4, int var5);

  void feature(FeatureStatus featureStatus);

//  void scenarioOutline(ScenarioOutline var1);

  // examples has to be separate so we can ensure text is inserted between the start of the scenario outline and the examples keyword
  void examples(GherkinTable examples);

  // always followed by "examples" if there are examples, but we have to have them as separate steps so we can insert info between them
  // start of scenario including any and all examples
  void startOfScenarioLifeCycle(Scenario startScenario);

  void background(Background background);

  void scenario(ScenarioStatus scenario);

  void step(StepStatus step);

  // end of scenario including any and all examples
  void endOfScenarioLifeCycle(Scenario endScenario);

  void done(Object status);

  void close();

  void eof(RunStatus status);
}