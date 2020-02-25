part of ogurets_core3;

class BasicFormatter implements Formatter {
  final ResultBuffer buffer;

  BasicFormatter(this.buffer);

  @override
  void background(Background background) {}

  @override
  void close() {}

  @override
  void done(Object status) {
    if (status is FeatureStatus) {
      FeatureStatus featureStatus = status;
      buffer.writeln("-------------------");
      buffer.writeln("Scenarios passed: ${featureStatus.passedScenariosCount}",
          color: 'green');

      if (featureStatus.failedScenariosCount > 0) {
        buffer.writeln(
            "Scenarios failed: ${featureStatus.failedScenariosCount}",
            color: 'red');
      }

      buffer.flush();
    } else if (status is StepStatus) {
      StepStatus ss = status;
      if (ss.failed) {
        buffer.writeln(
            "Step: ${ss.decodedVerbiage} failed (${ss.step.location.toString()}:\n${ss.failure.error}: ${ss.failure.trace}",
            color: 'red');
      }
    }
  }

  @override
  void endOfScenarioLifeCycle(Scenario endScenario) {}

  @override
  void eof(RunStatus runStatus) {
    // Tally the failed / passed features
    buffer.writeln("==================");
    if (runStatus.passedFeaturesCount > 0) {
      buffer.writeln("Features passed: ${runStatus.passedFeaturesCount}",
          color: "green");
    }
    if (runStatus.failedFeaturesCount > 0) {
      buffer.writeln("Features failed: ${runStatus.failedFeaturesCount}",
          color: "red");
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
      buffer.write(
          "\n\t${startScenario.scenario.gherkinKeyword}: ${startScenario.scenario.name}");
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
      buffer.writeln(
          "\t\t${status.decodedVerbiage}\n\"\"\"\n${status.step.pyString}\"\"\"$failureMessage",
          color: color);
    } else {
      buffer.write("\t\t${status.decodedVerbiage}", color: color);
      buffer.write("\t${status.step.location}", color: 'gray');

      if (status.step.table.isNotEmpty) {
        buffer.write("\n${status.step.table.gherkinRows().join("\n")}",
            color: 'cyan');
      }

      if (status.out.isNotEmpty) {
        buffer.write("\n");
        buffer.write(status.out.toString());
      }

      buffer.writeln(failureMessage, color: color);
    }

    buffer.flush();
  }

  @override
  void syntaxError(
      String var1, String var2, List<String> var3, String var4, int var5) {
    // TODO: implement syntaxError
  }

  void uri(String url) {
    // TODO: implement uri
  }
}