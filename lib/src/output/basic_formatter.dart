part of '../../ogurets.dart';

class BasicFormatter implements Formatter {
  final ResultBuffer buffer;

  /// Whether [eof] reprints every failed scenario, step by step with its
  /// error and stack trace, so failures are easy to find in long runs.
  final bool failureSummary;

  BasicFormatter(this.buffer, {this.failureSummary = true});

  @override
  void background(GherkinBackground background) {}

  @override
  void close() {}

  @override
  void done(Object? status) {
    if (status is FeatureStatus) {
      // pass/fail totals are written once for the whole run, in [eof]
      buffer.writeln("-------------------");
      buffer.write("Feature time: ${status.duration.inMilliseconds} ms");
    } else if (status is ScenarioStatus) {
      // only write for the whole scenario - background will be reflected in the scenario status
      if (status.scenario is! GherkinBackground) {
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
      if (status.step!.hook) {
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
        failureMessage = "\n${status.failure!.error}\n${status.failure!.trace}";
      }

      // always write out the verbiage - this will be the step text
      buffer.write("\t\t${status.decodedVerbiage}", color: color);

      if (status.step!.pyString != null) {
        buffer.writeln("\n\"\"\n${status.step!.pyString}\"\"\"");
      } else {
        buffer.write("\t${status.step!.location}", color: 'gray');
      }

      // write out the table to match irrespective of status
      // don't write a newline after the last row to keep inline with the steps
      if (status.step!.table.isNotEmpty) {
        var counter = 0;
        buffer.write("\n");
        var rows = status.step!.table.gherkinRows();
        for (var row in rows) {
          buffer.write(row, color: counter == 0 ? 'magenta' : 'cyan');
          counter < rows.length - 1 ? buffer.write("\n") : null;
          counter++;
        }
      }

      if (failureMessage.isNotEmpty) {
        buffer.writeln(failureMessage);
      }

      // need to write out when it's done, or it won't have anything
      // because fmt.step writes before execution. Output is only shown for
      // failed steps, unless ALWAYS_SHOW_OUT is set.
      if (status.out.isNotEmpty && (status.failed || alwaysShowOut)) {
        buffer.write("\n");
        buffer.write(status.out.toString());
      }
    }

    buffer.flush();
  }

  @override
  void endOfScenarioLifeCycle(GherkinScenario endScenario) {}

  @override
  void eof(RunStatus runStatus) {
    if (failureSummary) {
      _writeFailedScenarios(runStatus);
    }

    // Tally the missing stepdefs boilerplate
    if (runStatus.undefinedStepsCount > 0) {
      buffer.writeln("\nMissing steps:", color: "yellow");
      buffer.write(runStatus.boilerplate, color: "yellow");
    }

    // totals for the whole run come last, so they are the final thing printed
    buffer.writeln("\n==================");

    buffer.writeln(
      "Scenarios passed: ${runStatus.passedScenarios}",
      color: 'green',
    );

    if (runStatus.skippedScenarios > 0) {
      buffer.writeln(
        "Scenarios skipped: ${runStatus.skippedScenarios}",
        color: 'gray',
      );
    }

    if (runStatus.failedScenarios > 0) {
      buffer.writeln(
        "Scenarios failed: ${runStatus.failedScenarios}",
        color: 'red',
      );
    }

    if (runStatus.passedFeaturesCount > 0) {
      buffer.writeln(
        "Features passed: ${runStatus.passedFeaturesCount}",
        color: "green",
      );
    }

    if (runStatus.skippedFeaturesCount > 0) {
      buffer.writeln(
        "Features skipped: ${runStatus.skippedFeaturesCount}",
        color: "gray",
      );
    }

    if (runStatus.failedFeaturesCount > 0) {
      buffer.writeln(
        "Features failed: ${runStatus.failedFeaturesCount}",
        color: "red",
      );
    }

    buffer.writeln("Run time: ${runStatus.duration.inMilliseconds} ms");

    buffer.flush();
  }

  /// Reprints each failed scenario: passed steps in green, the failed step in
  /// red followed by its error and stack trace, skipped steps in gray and
  /// undefined steps in yellow. Hooks are only shown when they failed.
  void _writeFailedScenarios(RunStatus runStatus) {
    final failedFeatures = runStatus.failedFeatures.where(
      (f) => f.failedScenarios.isNotEmpty,
    );
    if (failedFeatures.isEmpty) {
      return;
    }

    buffer.writeln("\nFailed scenarios:", color: 'red');

    for (final featureStatus in failedFeatures) {
      buffer.write("\nFeature: ${featureStatus.feature.name}");
      buffer.writeln("${featureStatus.feature.location}", color: 'gray');

      for (final scenarioStatus in featureStatus.failedScenarios) {
        _writeFailedScenario(scenarioStatus);
      }
    }
  }

  void _writeFailedScenario(ScenarioStatus status) {
    final scenario = status.scenario!;
    buffer.write("\n\t${scenario.gherkinKeyword}: ${status.decodedName}");
    buffer.writeln("${scenario.location}", color: 'gray');

    if (status.exampleTable.isValid) {
      final names = status.exampleTable.names;
      buffer.writeln("\t  Example:", color: 'cyan');
      buffer.writeln("\t\t  |${names.join(" | ")}|", color: 'magenta');
      buffer.writeln(
        "\t\t  |${names.map((n) => status.example[n] ?? '').join(" | ")}|",
        color: 'cyan',
      );
    }

    var inBackground = false;
    for (final stepStatus in status.executedSteps) {
      final step = stepStatus.step!;

      // passing hooks are noise here, but a failing one is often the cause
      if (step.hook && !stepStatus.failed) {
        continue;
      }

      final isBackground = step.scenario is GherkinBackground;
      if (isBackground != inBackground) {
        inBackground = isBackground;
        if (isBackground) {
          buffer.writeln(
            "\t  ${step.scenario!.gherkinKeyword}:",
            color: 'gray',
          );
        }
      }

      final color = stepStatus.failed
          ? 'red'
          : !stepStatus.defined
          ? 'yellow'
          : stepStatus.skipped
          ? 'gray'
          : 'green';
      final suffix = !stepStatus.defined ? " (undefined)" : "";

      // background steps sit one level deeper, under their own heading
      final indent = isBackground ? "\t\t  " : "\t\t";
      buffer.write(
        "$indent${step.hook ? "" : "${step.verb} "}${stepStatus.decodedVerbiage}$suffix",
        color: color,
      );
      buffer.writeln("\t${step.location}", color: 'gray');

      if (step.pyString != null) {
        buffer.writeln('\t\t  """', color: color);
        for (final line in step.pyString!.trimRight().split('\n')) {
          buffer.writeln("\t\t  $line", color: color);
        }
        buffer.writeln('\t\t  """', color: color);
      }

      for (final row in step.table.gherkinRows()) {
        buffer.writeln(row, color: color);
      }

      final failure = stepStatus.failure;
      if (failure != null) {
        _writeStepOutput(stepStatus);
        buffer.writeln("\n${failure.error}", color: 'red');
        final trace = failure.trace?.trimRight() ?? '';
        if (trace.isNotEmpty) {
          buffer.writeln("$trace\n");
        }
      }
    }
  }

  /// The output a failed step captured (`out`, `print` and log messages).
  void _writeStepOutput(StepStatus stepStatus) {
    final output = stepStatus.out.toString().trimRight();
    if (output.isEmpty) {
      return;
    }

    buffer.writeln("\t\t  Output:", color: 'gray');
    for (final line in output.split('\n')) {
      buffer.writeln("\t\t  | $line", color: 'gray');
    }
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
        "\n\t${startScenario.scenario!.gherkinKeyword}: ${startScenario.decodedName}",
      );
      buffer.writeln("${startScenario.scenario!.location}", color: 'gray');
    }
  }

  @override
  void startOfScenarioLifeCycle(GherkinScenario scenario) {
    if (scenario is GherkinBackground) {
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
    String var1,
    String var2,
    List<String> var3,
    String var4,
    int var5,
  ) {
    // TODO: implement syntaxError
  }

  void uri(String url) {
    // TODO: implement uri
  }
}
