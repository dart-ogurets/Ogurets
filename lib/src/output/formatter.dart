part of dherkin_core3;

// https://github.com/JetBrains/intellij-community/blob/master/plugins/cucumber-jvm-formatter/src/org/jetbrains/plugins/cucumber/java/run/CucumberJvmSMFormatter.java


/**
 * This is the interface you should implement if you want your own custom
 * formatter.
 */
abstract class Formatter {
  void syntaxError(String var1, String var2, List<String> var3, String var4,
      int var5);

  void uri(String url);

  void feature(FeatureStatus featureStatus);

//  void scenarioOutline(ScenarioOutline var1);

  void examples(GherkinTable examples);

  void examplesEnd() {}

  void startOfScenarioLifeCycle(ScenarioStatus startScenario);

  void background(Background background);

  void scenario(ScenarioStatus scenario);

  void step(StepStatus step);

  void endOfScenarioLifeCycle(ScenarioStatus endScenario);

  void done(BufferedStatus status);

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
  void done(BufferedStatus status) {
    formatters.forEach((f) => f.done(status));
  }

  @override
  void endOfScenarioLifeCycle(ScenarioStatus endScenario) {
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
  void startOfScenarioLifeCycle(ScenarioStatus startScenario) {
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

  @override
  void uri(String url) {
    formatters.forEach((f) => f.uri(url));
  }

  @override
  void examplesEnd() {
    formatters.forEach((f) => f.examplesEnd());
  }
}

class BasicFormatter implements Formatter {
  final ResultBuffer buffer;

  BasicFormatter(this.buffer);

  @override
  void background(Background background) {
    // TODO: implement background
  }

  @override
  void close() {
    // TODO: implement close
  }

  @override
  void done(BufferedStatus status) {
    if (status is FeatureStatus) {
      FeatureStatus featureStatus = status;
      buffer.writeln("-------------------");
      buffer.writeln("Scenarios passed: ${featureStatus.passedScenariosCount}", color: 'green');

      if (featureStatus.failedScenariosCount > 0) {
        buffer.writeln("Scenarios failed: ${featureStatus.failedScenariosCount}", color: 'red');
      }

      buffer.flush();
    }
  }

  @override
  void endOfScenarioLifeCycle(ScenarioStatus endScenario) {
    // TODO: implement endOfScenarioLifeCycle
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
  void scenario(ScenarioStatus var1) {
    // TODO: implement scenario
  }

  @override
  void startOfScenarioLifeCycle(ScenarioStatus startScenario) {
    buffer.write("\n\t${startScenario.scenario.gherkinKeyword}: ${startScenario.scenario.name}");
    buffer.writeln("${startScenario.scenario.location}", color: 'gray');
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
      buffer.writeln("\t\t${status.step.verbiage}\n\"\"\"\n${status.step.pyString}\"\"\"$failureMessage", color: color);
    } else {
      buffer.write("\t\t${status.step.verbiage}", color: color);
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
  }

  @override
  void syntaxError(String var1, String var2, List<String> var3, String var4, int var5) {
    // TODO: implement syntaxError
  }

  @override
  void uri(String url) {
    // TODO: implement uri
  }

  @override
  void examplesEnd() {
    // TODO: implement examplesEnd
  }

}


class IntellijFormatter implements Formatter {
  final ResultBuffer buffer;
  static const String TEAMCITY_PREFIX = "##teamcity";

  static DateFormat DATE_FORMAT = DateFormat("yyyy-MM-dd'T'hh:mm:ss.SSSZ");

  static const String FILE_RESOURCE_PREFIX = "file://";

  static const String TEMPLATE_TEST_STARTED =
      TEAMCITY_PREFIX +
          "[testStarted timestamp = '%s' locationHint = '%s' captureStandardOutput = 'true' name = '%s']";
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

  IntellijFormatter(this.buffer);

  bool _endedByNewLine;
  final Queue<String> _queue = new Queue();
  FeatureStatus currentFeature = null;
  String _uri = "";

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

  String _getFeatureName(String featureHeader) {
    var lines = featureHeader.split("\n");
    lines.removeWhere((l) =>
    l.length == 0 || l[0] == '#' || l[0] == '@' || l.indexOf(':') < 0);
    if (lines.length > 0) {
      return lines[0];
    } else {
      return featureHeader;
    }
  }

  void out(String template, List params) {
    outCommand(template, false, params);
  }

  void outCommand(String command, bool waitForScenario,
      List<String> parameters) {
    String line = _escapeCommand(command, parameters);
    if (waitForScenario) {
      _queue.add(line);
    } else {
      try {
        if (!_endedByNewLine) {
          buffer.write("\n");
        }
        buffer.write(line);
        buffer.write("\n");
        _endedByNewLine = true;
      }catch(ignored) {
      }
    }
  }

  String getCurrentTime() {
    return DATE_FORMAT.format(DateTime.now());
  }

  @override
  void background(Background background) {
    // TODO: implement background
  }

  @override
  void close() {
    // TODO: implement close
  }

  @override
  void done(BufferedStatus status) {
    if (status == currentFeature) {
      currentFeature = null;
    }
  }

  @override
  void endOfScenarioLifeCycle(ScenarioStatus endScenario) {
    // TODO: implement endOfScenarioLifeCycle
  }


  @override
  void examples(GherkinTable examples) {
    // TODO: implement examples
  }

  @override
  void feature(FeatureStatus featureStatus) {
    if (currentFeature != null) {
      done(currentFeature);
    }
    currentFeature = featureStatus;
    var currentFeatureName = "Feature: " + featureStatus.feature.name;
    _uri = featureStatus.feature.location.srcFilePath;
    out(TEMPLATE_TEST_SUITE_STARTED, [getCurrentTime(), _uri + ":" + featureStatus.feature.name, currentFeatureName]);
  }

  void _closeScenario() {

  }

  @override
  void scenario(ScenarioStatus scenario) {
//    _closeScenario();
//    out(TEMPLATE_SCENARIO_STARTED, [getCurrentTime()]);
//    if (isRealScenario(scenario)) {
//      scenarioCount++;
//      closeScenarioOutline();
//      currentSteps.clear();
//    }
//    currentScenario = scenario;
//    beforeExampleSection = false;
//    outCommand(TEMPLATE_TEST_SUITE_STARTED, getCurrentTime(), uri + ":" + scenario.getLine(), getName(currentScenario));
//
//    while (queue.size() > 0) {
//      String smMessage = queue.poll();
//      outCommand(smMessage);
//    }
  }

  @override
  void startOfScenarioLifeCycle(ScenarioStatus startScenario) {
    // TODO: implement startOfScenarioLifeCycle
  }

  @override
  void step(StepStatus step) {
    // TODO: implement step
  }

  @override
  void syntaxError(String var1, String var2, List<String> var3, String var4,
      int var5) {
    // TODO: implement syntaxError
  }

  @override
  void uri(String url) {
    // TODO: implement uri
  }

  @override
  void examplesEnd() {
    // TODO: implement examplesEnd
  }

  @override
  void eof(RunStatus status) {
    // TODO: implement eof
  }

}
