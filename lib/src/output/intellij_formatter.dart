part of ogurets;

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
  BasicFormatter _basicFormatter;
  String _currentDirectory;

  static const String TEAMCITY_PREFIX = "##teamcity";

  static DateFormat DATE_FORMAT = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");

  static const String FILE_RESOURCE_PREFIX = "file://";

  static const String TEMPLATE_TEST_STARTED = TEAMCITY_PREFIX +
      "[testStarted timestamp = '%s' locationHint = 'file://%s' captureStandardOutput = 'true' name = '%s']";
  static const String TEMPLATE_TEST_FAILED = TEAMCITY_PREFIX +
      "[testFailed timestamp = '%s' details = '%s' message = '%s' name = '%s' %s]";
  static const String TEMPLATE_COMPARISON_TEST_FAILED = TEAMCITY_PREFIX +
      "[testFailed timestamp = '%s' details = '%s' message = '%s' expected='%s' actual='%s' name = '%s' %s]";
  static const String TEMPLATE_SCENARIO_FAILED = TEAMCITY_PREFIX +
      "[customProgressStatus timestamp='%s' type='testFailed']";
  static const String TEMPLATE_TEST_PENDING = TEAMCITY_PREFIX +
      "[testIgnored name = '%s' message = 'Skipped step' timestamp = '%s']";

  static const String TEMPLATE_TEST_FINISHED = TEAMCITY_PREFIX +
      "[testFinished timestamp = '%s' duration = '%s' name = '%s']";

  static const String TEMPLATE_ENTER_THE_MATRIX =
      TEAMCITY_PREFIX + "[enteredTheMatrix timestamp = '%s']";

  static const String TEMPLATE_TEST_SUITE_STARTED = TEAMCITY_PREFIX +
      "[testSuiteStarted timestamp = '%s' locationHint = 'file://%s' name = '%s']";
  static const String TEMPLATE_TEST_SUITE_FINISHED =
      TEAMCITY_PREFIX + "[testSuiteFinished timestamp = '%s' name = '%s']";

  static const String TEMPLATE_SCENARIO_COUNTING_STARTED = TEAMCITY_PREFIX +
      "[customProgressStatus testsCategory = 'Scenarios' count = '%s' timestamp = '%s']";
  static const String TEMPLATE_SCENARIO_COUNTING_FINISHED = TEAMCITY_PREFIX +
      "[customProgressStatus testsCategory = '' count = '0' timestamp = '%s']";
  static const String TEMPLATE_SCENARIO_STARTED = TEAMCITY_PREFIX +
      "[customProgressStatus type = 'testStarted' timestamp = '%s']";
  static const String TEMPLATE_SCENARIO_FINISHED = TEAMCITY_PREFIX +
      "[customProgressStatus type = 'testFinished' timestamp = '%s']";

  IntellijFormatter(this.buffer) {
    this._basicFormatter = BasicFormatter(this.buffer);
    out(TEMPLATE_ENTER_THE_MATRIX, [getCurrentTime()]);
    out(TEMPLATE_SCENARIO_COUNTING_STARTED, ["0", getCurrentTime()]);

    _currentDirectory = Directory.current.path;
  }

  FeatureStatus currentFeature;

  static String _escape(String source) {
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

  static String _escapeCommand(String command, List<String> parameters) {
    var escapedParameters = parameters.map((p) => _escape(p)).toList();

    return sprintf(command, escapedParameters);
  }

  String _getFeatureName(FeatureStatus feature) {
    String featureHeader = feature.feature.name;
    var lines = featureHeader.split("\n");
    lines.removeWhere(
        (l) => l.isEmpty || l[0] == '#' || l[0] == '@' || !l.contains(':'));
    if (lines.isNotEmpty) {
      return 'Feature: ${lines[0]}';
    } else {
      return 'Feature: ${featureHeader}';
    }
  }

  void out(String template, List<String> params) {
    buffer.writeln(_escapeCommand(template, params));
    buffer.flush();
  }

  String getCurrentTime() {
    return DATE_FORMAT.format(DateTime.now());
  }

  @override
  void background(_Background background) {
    _basicFormatter.background(background);
  }

  @override
  void close() {
    _basicFormatter.close();
  }

  @override
  void done(Object status) {
    _basicFormatter.done(status);

    if (status == currentFeature) {
      out(TEMPLATE_TEST_SUITE_FINISHED,
          [getCurrentTime(), _getFeatureName(currentFeature)]);
    } else if (status is StepStatus) {
      StepStatus ss = status;
      if (ss.failed) {
        out(TEMPLATE_TEST_FAILED, [
          getCurrentTime(),
          _location(ss.step.location),
          ss.failure.error.toString(),
          ss.decodedVerbiage,
          ''
        ]);
      } else if (ss.skipped) {
        out(TEMPLATE_TEST_PENDING, [ss.decodedVerbiage, getCurrentTime()]);
      }

      out(TEMPLATE_TEST_FINISHED, [
        getCurrentTime(),
        ss.duration.inSeconds.toString(),
        ss.decodedVerbiage
      ]);
    } else if (status is GherkinTable) {
      out(TEMPLATE_TEST_SUITE_FINISHED, [getCurrentTime(), "Examples:"]);
      out(TEMPLATE_SCENARIO_FINISHED, [getCurrentTime()]);
    } else if (status is ScenarioStatus) {
      ScenarioStatus scenario = status;
      if (scenario.failed) {
        out(TEMPLATE_SCENARIO_FAILED, [getCurrentTime()]);
      }
      out(TEMPLATE_TEST_SUITE_FINISHED,
          [getCurrentTime(), _getScenarioName(scenario)]);

      out(TEMPLATE_SCENARIO_FINISHED, [getCurrentTime()]);
    }
  }

  @override
  void feature(FeatureStatus featureStatus) {
    if (currentFeature != null) {
      done(currentFeature);
    }
    currentFeature = featureStatus;
    out(TEMPLATE_TEST_SUITE_STARTED, [
      getCurrentTime(),
      _location(featureStatus.feature.location),
      _getFeatureName(featureStatus)
    ]);

    _basicFormatter.feature(featureStatus);
  }

  @override
  void examples(GherkinTable examples) {
    out(TEMPLATE_SCENARIO_STARTED, [getCurrentTime()]);
    out(TEMPLATE_TEST_SUITE_STARTED, [getCurrentTime(), "", "Examples:"]);
    _basicFormatter.examples(examples);
  }

  @override
  void startOfScenarioLifeCycle(_Scenario startScenario) {
    _basicFormatter.startOfScenarioLifeCycle(startScenario);
  }

  @override
  void endOfScenarioLifeCycle(_Scenario endScenario) {
    _basicFormatter.endOfScenarioLifeCycle(endScenario);
  }

  @override
  void scenario(ScenarioStatus scenario) {
    out(TEMPLATE_SCENARIO_STARTED, [getCurrentTime()]);
    out(TEMPLATE_TEST_SUITE_STARTED, [
      getCurrentTime(),
      _location(scenario.scenario.location),
      _getScenarioName(scenario)
    ]);

    _basicFormatter.scenario(scenario);
  }

  @override
  void step(StepStatus step) {
    out(TEMPLATE_TEST_STARTED, [
      getCurrentTime(),
      _location(step.step.location),
      step.decodedVerbiage
    ]);
    _basicFormatter.step(step);
  }

  String _location(Location location) {
    return "${_currentDirectory}/${location.srcFilePath}:${location.srcLineNumber}";
  }

  @override
  void syntaxError(
      String var1, String var2, List<String> var3, String var4, int var5) {
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
