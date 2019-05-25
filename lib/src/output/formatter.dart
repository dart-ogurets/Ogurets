part of ogurets_core3;

// https://github.com/JetBrains/intellij-community/blob/master/plugins/cucumber-jvm-formatter/src/org/jetbrains/plugins/cucumber/java/run/CucumberJvmSMFormatter.java


/**
 * This is the interface you should implement if you want your own custom
 * formatter.
 */
abstract class Formatter {
  void syntaxError(String var1, String var2, List<String> var3, String var4,
      int var5);

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

class Result {
  final String status;
  final int duration;
  final String error_message;
  final Exception error;
  final Result SKIPPED = new Result("skipped", null);
  final Result UNDEFINED = new Result("undefined", null);
  final String PASSED = "passed";
  final String FAILED = "failed";

  Result(this.status, this.duration, {this.error, this.error_message});
}

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
  void syntaxError(String var1, String var2, List<String> var3, String var4, int var5) {
    formatters.forEach((f) => f.syntaxError(var1, var2, var3, var4, var5));
  }
}

class BasicFormatter implements Formatter {
  final ResultBuffer buffer;

  BasicFormatter(this.buffer);

  @override
  void background(Background background) {
  }

  @override
  void close() {
  }

  @override
  void done(Object status) {
    if (status is FeatureStatus) {
      FeatureStatus featureStatus = status;
      buffer.writeln("-------------------");
      buffer.writeln("Scenarios passed: ${featureStatus.passedScenariosCount}", color: 'green');

      if (featureStatus.failedScenariosCount > 0) {
        buffer.writeln("Scenarios failed: ${featureStatus.failedScenariosCount}", color: 'red');
      }

      buffer.flush();
    } else if (status is StepStatus) {
      StepStatus ss = status as StepStatus;
      if (ss.failed) {
        buffer.writeln("Step: ${ss.decodedVerbiage} failed (${ss.step.location.toString()}:\n${ss.failure.error}: ${ss.failure.trace}", color: 'red');
      }
    }
  }

  @override
  void endOfScenarioLifeCycle(Scenario endScenario) {
  }

  @override
  void eof(RunStatus runStatus) {
    // Tally the failed / passed features
    buffer.writeln("==================");
    if (runStatus.passedFeaturesCount > 0) {
      buffer.writeln("Features passed: ${runStatus.passedFeaturesCount}", color: "green");
    }
    if (runStatus.failedFeaturesCount > 0) {
      buffer.writeln("Features failed: ${runStatus.failedFeaturesCount}", color: "red");
    }
    buffer.flush();
    // Tally the missing stepdefs boilerplate
    buffer.write(runStatus.boilerplate, color: "yellow");
    buffer.flush();
  }

  @override
  void examples(GherkinTable examples) {
    buffer.writeln("\t  Examples: ", color: 'cyan');
    var counter = 0;
    examples.gherkinRows().forEach((row) {
      buffer.writeln(row, color: counter == 0 ? 'magenta' : 'green');
      counter++;
    });
    buffer.flush();
  }

  @override
  void feature(FeatureStatus featureStatus) {
    buffer.write("\nFeature: ${featureStatus.feature.name}");
    buffer.writeln("${featureStatus.feature.location}", color: 'gray');
  }

  @override
  void scenario(ScenarioStatus startScenario) {
    if (!startScenario.exampleTable.isValid) {
      buffer.write("\n\t${startScenario.scenario.gherkinKeyword}: ${startScenario.scenario.name}");
      buffer.writeln("${startScenario.scenario.location}", color: 'gray');
    }
  }

  @override
  void startOfScenarioLifeCycle(Scenario scenario) {
    buffer.write("\n\t${scenario.gherkinKeyword}: ${scenario.name}");
    buffer.writeln("${scenario.location}", color: 'gray');
  }

  @override
  void step(StepStatus status) {
    var color = "green";
    var failureMessage = "";

    if (!status.defined) {
      color = "yellow";
    }
    if (status.failed) {
      color = "red";
      failureMessage = "\n${status.failure.error}\n${status.failure.trace}";
    }
    if (status.step.pyString != null) {
      buffer.writeln("\t\t${status.decodedVerbiage}\n\"\"\"\n${status.step.pyString}\"\"\"$failureMessage", color: color);
    } else {
      buffer.write("\t\t${status.decodedVerbiage}", color: color);
      buffer.write("\t${status.step.location}", color: 'gray');

      if (!status.step.table.isEmpty) {
        buffer.write("\n${status.step.table.gherkinRows().join("\n")}", color: 'cyan');
      }

      if(status.out.isNotEmpty) {
        buffer.write("\n");
        buffer.write(status.out.toString());
      }

      buffer.writeln(failureMessage, color: color);
    }

    buffer.flush();
  }

  @override
  void syntaxError(String var1, String var2, List<String> var3, String var4, int var5) {
    // TODO: implement syntaxError
  }

  @override
  void uri(String url) {
    // TODO: implement uri
  }


}


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

  static const String TEMPLATE_TEST_STARTED =
      TEAMCITY_PREFIX +
          "[testStarted timestamp = '%s' locationHint = 'file://%s' captureStandardOutput = 'true' name = '%s']";
  static const String TEMPLATE_TEST_FAILED =
      TEAMCITY_PREFIX +
          "[testFailed timestamp = '%s' details = '%s' message = '%s' name = '%s' %s]";
  static const String TEMPLATE_COMPARISON_TEST_FAILED =
      TEAMCITY_PREFIX +
          "[testFailed timestamp = '%s' details = '%s' message = '%s' expected='%s' actual='%s' name = '%s' %s]";
  static const String TEMPLATE_SCENARIO_FAILED = TEAMCITY_PREFIX +
      "[customProgressStatus timestamp='%s' type='testFailed']";
  static const String TEMPLATE_TEST_PENDING =
      TEAMCITY_PREFIX +
          "[testIgnored name = '%s' message = 'Skipped step' timestamp = '%s']";

  static const String TEMPLATE_TEST_FINISHED =
      TEAMCITY_PREFIX +
          "[testFinished timestamp = '%s' duration = '%s' name = '%s']";

  static const String TEMPLATE_ENTER_THE_MATRIX = TEAMCITY_PREFIX +
      "[enteredTheMatrix timestamp = '%s']";

  static const String TEMPLATE_TEST_SUITE_STARTED =
      TEAMCITY_PREFIX +
          "[testSuiteStarted timestamp = '%s' locationHint = 'file://%s' name = '%s']";
  static const String TEMPLATE_TEST_SUITE_FINISHED = TEAMCITY_PREFIX +
      "[testSuiteFinished timestamp = '%s' name = '%s']";

  static const String TEMPLATE_SCENARIO_COUNTING_STARTED =
      TEAMCITY_PREFIX +
          "[customProgressStatus testsCategory = 'Scenarios' count = '%s' timestamp = '%s']";
  static const String TEMPLATE_SCENARIO_COUNTING_FINISHED =
      TEAMCITY_PREFIX +
          "[customProgressStatus testsCategory = '' count = '0' timestamp = '%s']";
  static const String TEMPLATE_SCENARIO_STARTED = TEAMCITY_PREFIX +
      "[customProgressStatus type = 'testStarted' timestamp = '%s']";
  static const String TEMPLATE_SCENARIO_FINISHED = TEAMCITY_PREFIX +
      "[customProgressStatus type = 'testFinished' timestamp = '%s']";

  IntellijFormatter(this.buffer) {
    this._basicFormatter = new BasicFormatter(this.buffer);
    out(TEMPLATE_ENTER_THE_MATRIX, [getCurrentTime()]);
    out(TEMPLATE_SCENARIO_COUNTING_STARTED, ["0", getCurrentTime()]);

    _currentDirectory = Directory.current.path;
  }

  bool _endedByNewLine;
  final Queue<String> _queue = new Queue();
  FeatureStatus currentFeature = null;

  static String _escape(String source) {
    if (source == null) {
      return "";
    }
    return source.replaceAll("|", "||").replaceAll("\n", "|n")
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
    lines.removeWhere((l) =>
    l.length == 0 || l[0] == '#' || l[0] == '@' || l.indexOf(':') < 0);
    if (lines.length > 0) {
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
  void background(Background background) {
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
      out(TEMPLATE_TEST_SUITE_FINISHED, [getCurrentTime(), _getFeatureName(currentFeature)]);
    } else if (status is StepStatus) {
      StepStatus ss = status;
      if (ss.failed) {
        out(TEMPLATE_TEST_FAILED, [getCurrentTime(), _location(ss.step.location), ss.failure.error.toString(), ss.decodedVerbiage, '']);
      } else if (ss.skipped) {
        out(TEMPLATE_TEST_PENDING, [ss.decodedVerbiage, getCurrentTime()]);
      }

      // TODO: add timing to step
      out(TEMPLATE_TEST_FINISHED, [getCurrentTime(), "1", ss.decodedVerbiage]);
    } else if (status is GherkinTable) {
      out(TEMPLATE_TEST_SUITE_FINISHED, [getCurrentTime(), "Examples:"]);
      out(TEMPLATE_SCENARIO_FINISHED, [getCurrentTime()]);
    } else if (status is ScenarioStatus) {
      ScenarioStatus scenario = status;
      out(TEMPLATE_TEST_SUITE_FINISHED, [getCurrentTime(), _getScenarioName(scenario)]);
      if (scenario.failed) {
        out(TEMPLATE_SCENARIO_FAILED, [getCurrentTime()]);
      }

      out(TEMPLATE_SCENARIO_FINISHED, [getCurrentTime()]);
    }
  }

  @override
  void feature(FeatureStatus featureStatus) {
    if (currentFeature != null) {
      done(currentFeature);
    }
    currentFeature = featureStatus;
    out(TEMPLATE_TEST_SUITE_STARTED, [getCurrentTime(), _location(featureStatus.feature.location), _getFeatureName(featureStatus)]);

    _basicFormatter.feature(featureStatus);
  }

  @override
  void examples(GherkinTable examples) {
    out(TEMPLATE_SCENARIO_STARTED, [getCurrentTime()]);
    out(TEMPLATE_TEST_SUITE_STARTED, [getCurrentTime(), "", "Examples:"]);
    _basicFormatter.examples(examples);
  }

  @override
  void startOfScenarioLifeCycle(Scenario startScenario) {
    _basicFormatter.startOfScenarioLifeCycle(startScenario);
  }

  @override
  void endOfScenarioLifeCycle(Scenario endScenario) {
    _basicFormatter.endOfScenarioLifeCycle(endScenario);
  }

  @override
  void scenario(ScenarioStatus scenario) {
    out(TEMPLATE_SCENARIO_STARTED, [getCurrentTime()]);
    out(TEMPLATE_TEST_SUITE_STARTED, [getCurrentTime(), _location(scenario.scenario.location), _getScenarioName(scenario)]);

    _basicFormatter.scenario(scenario);
  }


  @override
  void step(StepStatus step) {
    out(TEMPLATE_TEST_STARTED, [getCurrentTime(), _location(step.step.location), step.decodedVerbiage]);
    _basicFormatter.step(step);
  }

  String _location(Location location) {
    return "${_currentDirectory}/${location.srcFilePath}:${location.srcLineNumber}";
  }

  @override
  void syntaxError(String var1, String var2, List<String> var3, String var4,
      int var5) {
    _basicFormatter.syntaxError(var1, var2, var3, var4, var5);
  }

  @override
  void eof(RunStatus status) {
    _basicFormatter.eof(status);
  }

  String _getScenarioName(ScenarioStatus startScenario) {
    return "Scenario: ${startScenario.scenario.name}";
  }
}
