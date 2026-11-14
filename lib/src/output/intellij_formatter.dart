part of '../../ogurets.dart';

/*

see: https://github.com/JetBrains/intellij-community/blob/master/plugins/cucumber-jvm-formatter/src/org/jetbrains/plugins/cucumber/java/run/CucumberJvmSMFormatter.java

 IDEA needs the format in:
[testSuiteStarted feature-name|scenario-name|"example:"|example-line]
  then each step or hook is a test
[testSuiteEnded name-from-above]

example name is specifically:
##teamcity[testSuiteStarted timestamp = '2019-04-25T12:00:06.729+1200' locationHint = 'file://' name = 'Examples:']
 */
class IntellijFormatter implements Formatter {
  final ResultBuffer buffer;
  late BasicFormatter _basicFormatter;
  String? _currentDirectory;

  static const String teamcityPrefix = "##teamcity";

  static DateFormat dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");

  static const String fileResourcePrefix = "file://";

  static const String templateTestStarted =
      "$teamcityPrefix[testStarted timestamp = '%s' locationHint = 'file://%s' captureStandardOutput = 'true' name = '%s']";
  static const String templateTestFailed =
      "$teamcityPrefix[testFailed timestamp = '%s' details = '%s' message = '%s' name = '%s' %s]";
  static const String templateComparisonTestFailed =
      "$teamcityPrefix[testFailed timestamp = '%s' details = '%s' message = '%s' expected='%s' actual='%s' name = '%s' %s]";
  static const String templateScenarioFailed =
      "$teamcityPrefix[customProgressStatus timestamp='%s' type='testFailed']";
  static const String templateTestPending =
      "$teamcityPrefix[testIgnored name = '%s' message = 'Skipped step' timestamp = '%s']";

  static const String templateTestFinished =
      "$teamcityPrefix[testFinished timestamp = '%s' duration = '%s' name = '%s']";

  static const String templateEnterTheMatrix =
      "$teamcityPrefix[enteredTheMatrix timestamp = '%s']";

  static const String templateTestSuiteStarted =
      "$teamcityPrefix[testSuiteStarted timestamp = '%s' locationHint = 'file://%s' name = '%s']";
  static const String templateTestSuiteFinished =
      "$teamcityPrefix[testSuiteFinished timestamp = '%s' name = '%s']";

  static const String templateScenarioCountingStarted =
      "$teamcityPrefix[customProgressStatus testsCategory = 'Scenarios' count = '%s' timestamp = '%s']";
  static const String templateScenarioCountingFinished =
      "$teamcityPrefix[customProgressStatus testsCategory = '' count = '0' timestamp = '%s']";
  static const String templateScenarioStarted =
      "$teamcityPrefix[customProgressStatus type = 'testStarted' timestamp = '%s']";
  static const String templateScenarioFinished =
      "$teamcityPrefix[customProgressStatus type = 'testFinished' timestamp = '%s']";

  IntellijFormatter(this.buffer) {
    // IntelliJ shows failures in its own test tree, so skip the console summary
    _basicFormatter = BasicFormatter(buffer, failureSummary: false);
    out(templateEnterTheMatrix, [getCurrentTime()]);
    out(templateScenarioCountingStarted, ["0", getCurrentTime()]);

    _currentDirectory = Directory.current.path;
  }

  FeatureStatus? currentFeature;

  static String _escape(String? source) {
    if (source == null) {
      return "";
    }
    return source
        .replaceAll("|", "||")
        .replaceAll('[', "|[")
        .replaceAll(']', "|]")
        .replaceAll("\n", "|n")
        .replaceAll("\r", "|r")
        .replaceAll("'", "|'");
  }

  static String? _escapeCommand(String command, List<String?> parameters) {
    var escapedParameters = parameters.map((p) => _escape(p)).toList();

    return sprintf(command, escapedParameters);
  }

  String _getFeatureName(FeatureStatus feature) {
    String featureHeader = feature.feature.name!;
    var lines = featureHeader.split("\n");
    lines.removeWhere(
      (l) => l.isEmpty || l[0] == '#' || l[0] == '@' || !l.contains(':'),
    );
    if (lines.isNotEmpty) {
      return 'Feature: ${lines[0]}';
    } else {
      return 'Feature: $featureHeader';
    }
  }

  void out(String template, List<String?> params) {
    buffer.writeln(_escapeCommand(template, params));
    buffer.flush();
  }

  String getCurrentTime() {
    return dateFormat.format(DateTime.now());
  }

  @override
  void background(GherkinBackground background) {
    _basicFormatter.background(background);
  }

  @override
  void close() {
    _basicFormatter.close();
  }

  @override
  void done(Object? status) {
    _basicFormatter.done(status);

    if (status == currentFeature) {
      out(templateTestSuiteFinished, [
        getCurrentTime(),
        _getFeatureName(currentFeature!),
      ]);
    } else if (status is StepStatus) {
      StepStatus ss = status;
      if (ss.failed) {
        out(templateTestFailed, [
          getCurrentTime(),
          _location(ss.step!.location),
          ss.failure!.error.toString(),
          ss.decodedVerbiage,
          '',
        ]);
      } else if (ss.skipped) {
        out(templateTestPending, [ss.decodedVerbiage, getCurrentTime()]);
      }

      out(templateTestFinished, [
        getCurrentTime(),
        ss.duration.inSeconds.toString(),
        ss.decodedVerbiage,
      ]);
    } else if (status is GherkinTable) {
      out(templateTestSuiteFinished, [getCurrentTime(), "Examples:"]);
      out(templateScenarioFinished, [getCurrentTime()]);
    } else if (status is ScenarioStatus) {
      ScenarioStatus scenario = status;
      if (scenario.failed) {
        out(templateScenarioFailed, [getCurrentTime()]);
      }
      out(templateTestSuiteFinished, [
        getCurrentTime(),
        _getScenarioName(scenario),
      ]);

      out(templateScenarioFinished, [getCurrentTime()]);
    }
  }

  @override
  void feature(FeatureStatus featureStatus) {
    if (currentFeature != null) {
      done(currentFeature);
    }
    currentFeature = featureStatus;
    out(templateTestSuiteStarted, [
      getCurrentTime(),
      _location(featureStatus.feature.location),
      _getFeatureName(featureStatus),
    ]);

    _basicFormatter.feature(featureStatus);
  }

  @override
  void examples(GherkinTable examples) {
    out(templateScenarioStarted, [getCurrentTime()]);
    out(templateTestSuiteStarted, [getCurrentTime(), "", "Examples:"]);
    _basicFormatter.examples(examples);
  }

  @override
  void startOfScenarioLifeCycle(GherkinScenario startScenario) {
    _basicFormatter.startOfScenarioLifeCycle(startScenario);
  }

  @override
  void endOfScenarioLifeCycle(GherkinScenario endScenario) {
    _basicFormatter.endOfScenarioLifeCycle(endScenario);
  }

  @override
  void scenario(ScenarioStatus scenario) {
    out(templateScenarioStarted, [getCurrentTime()]);
    out(templateTestSuiteStarted, [
      getCurrentTime(),
      _location(scenario.scenario!.location),
      _getScenarioName(scenario),
    ]);

    _basicFormatter.scenario(scenario);
  }

  @override
  void step(StepStatus step) {
    out(templateTestStarted, [
      getCurrentTime(),
      _location(step.step!.location),
      step.decodedVerbiage,
    ]);
    _basicFormatter.step(step);
  }

  String _location(Location location) {
    return "$_currentDirectory/${location.srcFilePath}:${location.srcLineNumber}";
  }

  @override
  void syntaxError(
    String var1,
    String var2,
    List<String> var3,
    String var4,
    int var5,
  ) {
    _basicFormatter.syntaxError(var1, var2, var3, var4, var5);
  }

  @override
  void eof(RunStatus status) {
    _basicFormatter.eof(status);
  }

  String _getScenarioName(ScenarioStatus startScenario) {
    return "Scenario: ${startScenario.decodedName}";
  }
}
