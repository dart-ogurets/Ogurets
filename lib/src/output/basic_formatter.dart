part of ogurets;

class BasicFormatter implements Formatter {
  final ResultBuffer buffer;

  BasicFormatter(this.buffer);

  @override
  void background(_Background background) {}

  @override
  void close() {}

  @override
  void done(Object status) {
    if (status is FeatureStatus) {
      buffer.writeln("-------------------");
      buffer.writeln("Scenarios passed: ${status.passedScenariosCount}",
          color: 'green');

      if (status.skippedScenariosCount > 0) {
        buffer.writeln("Scenarios skipped: ${status.skippedScenariosCount}",
            color: 'gray');
      }

      if (status.failedScenariosCount > 0) {
        buffer.writeln("Scenarios failed: ${status.failedScenariosCount}",
            color: 'red');
      }

      buffer.write("Feature time: ${status.duration.inMilliseconds} ms");
    } else if (status is ScenarioStatus) {
      // only write for the whole scenario - background will be reflected in the scenario status
      if (!(status.scenario is _Background)) {
        if ((status.failed || status.undefinedStepsCount > 0)) {
          buffer.writeln("Scenario failed!", color: 'red');
        } else {
          buffer.writeln("Scenario passed!", color: 'green');
        }

        buffer.write("Scenario time: ${status.duration.inMilliseconds} ms");
      }
    } else if (status is StepStatus) {
      var color = 'green';
      var failureMessage = "";

      // set the color based on status or type
      if (status.step.hook) {
        color = 'blue';
        buffer.write("\t");
      }

      if (status.skipped) {
        color = 'gray';
      }

      if (!status.defined) {
        color = 'yellow';
      }

      if (status.failed) {
        color = "red";
        failureMessage = "\n${status.failure.error}\n${status.failure.trace}";
      }

      // always write out the verbiage - this will be the step text
      buffer.write("\t\t${status.decodedVerbiage}", color: color);

      if (status.step.pyString != null) {
        buffer.writeln("\n\"\"\n${status.step.pyString}\"\"\"");
      } else {
        buffer.write("\t${status.step.location}", color: 'gray');
      }

      // write out the table to match irrespective of status
      // don't write a newline after the last row to keep inline with the steps
      if (status.step.table.isNotEmpty) {
        var counter = 0;
        buffer.write("\n");
        var rows = status.step.table.gherkinRows();
        rows.forEach((row) {
          buffer.write(row, color: counter == 0 ? 'magenta' : 'cyan');
          counter < rows.length - 1 ? buffer.write("\n") : null;
          counter++;
        });
      }

      if (failureMessage.isNotEmpty) {
        buffer.writeln(failureMessage);
      }

      // need to write out when it's done, or it won't have anything
      // because fmt.step writes before execution
      if (status.out.isNotEmpty) {
        buffer.write("\n");
        buffer.write(status.out.toString());
      }
    }

    buffer.flush();
  }

  @override
  void endOfScenarioLifeCycle(_Scenario endScenario) {}

  @override
  void eof(RunStatus runStatus) {
    buffer.writeln("==================");

    // Tally the passed / skipped / failed features
    if (runStatus.passedFeaturesCount > 0) {
      buffer.writeln("Features passed: ${runStatus.passedFeaturesCount}",
          color: "green");
    }

    if (runStatus.skippedFeaturesCount > 0) {
      buffer.writeln("Features skipped: ${runStatus.skippedFeaturesCount}",
          color: "gray");
    }

    if (runStatus.failedFeaturesCount > 0) {
      buffer.writeln("Features failed: ${runStatus.failedFeaturesCount}",
          color: "red");
    }

    buffer.writeln("Run time: ${runStatus.duration.inMilliseconds} ms");

    // Tally the missing stepdefs boilerplate
    if (runStatus.undefinedStepsCount > 0) {
      buffer.writeln("\nMissing steps:", color: "yellow");
      buffer.write(runStatus.boilerplate, color: "yellow");
    }

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
    if (startScenario.exampleTable.isValid) {
      buffer.write(
          "\n\t${startScenario.scenario.gherkinKeyword}: ${startScenario.scenario.name}");
      buffer.writeln("${startScenario.scenario.location}", color: 'gray');
    }
  }

  @override
  void startOfScenarioLifeCycle(_Scenario scenario) {
    if (scenario is _Background) {
      buffer.write("\t");
    } else {
      buffer.write("\n");
    }

    buffer.write("\t${scenario.gherkinKeyword}: ${scenario.name}");
    buffer.writeln("${scenario.location}", color: 'gray');
  }

  @override
  void step(StepStatus status) {}

  @override
  void syntaxError(
      String var1, String var2, List<String> var3, String var4, int var5) {
    // TODO: implement syntaxError
  }

  void uri(String url) {
    // TODO: implement uri
  }
}
