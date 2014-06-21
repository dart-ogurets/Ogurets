part of dherkin_core;


class Feature {

  String name;
  List<String> tags;

  Scenario background = _NOOP;
  List<Scenario> scenarios = [];

  Location location;

  Feature(this.name, this.location);

  Future<FeatureStatus> execute(Map<RegExp, Function> stepRunners,
                 { List<String> runTags, Worker worker, bool debug: false }) {
    if (runTags == null) runTags = [];
    FeatureStatus featureStatus = new FeatureStatus()
      ..feature = this;

    if (_tagsMatch(tags, runTags)) {
      featureStatus.buffer.write("\nFeature: $name");
      featureStatus.buffer.writeln("$location", color: 'gray');

      var completer = new Completer();
      var results = [];
      Future.forEach(scenarios, (Scenario scenario) {
        _log.debug("Requested tags: $runTags.  Scenario is tagged with: ${scenario.tags}");
        if (_tagsMatch(scenario.tags, runTags)) {
          _log.debug("Executing Scenario: $scenario");

          scenario.background = background;

          Future scenarioFuture;
          if (worker != null) {
            // the Task will re-fetch the stepRunners, as we can't send them here.
            scenarioFuture = worker.handle(new ScenarioExecutionTask(scenario, debug: debug));
          } else {
            scenarioFuture = scenario.execute(stepRunners);
          }

          scenarioFuture.then((ScenarioStatus scenarioStatus) {

            featureStatus.buffer.merge(scenarioStatus.buffer);

            if (scenarioStatus.failed) {
              featureStatus.failedScenarios.add(scenarioStatus);
            } else {
              featureStatus.passedScenarios.add(scenarioStatus);
            }

          }).catchError((e, s) {
            _log.debug("ERROR $e \n $s");
          });

          results.add(scenarioFuture);
        } else {
          _log.debug("Skipping Scenario: $scenario");
        }
      }).whenComplete(() {
        Future.wait(results).whenComplete(() {
          featureStatus.buffer.writeln("-------------------");
          featureStatus.buffer.writeln("Scenarios passed: ${featureStatus.passedScenariosCount}", color: 'green');

          if (featureStatus.failedScenariosCount > 0) {
            featureStatus.buffer.writeln("Scenarios failed: ${featureStatus.failedScenariosCount}", color: 'red');
          }

          completer.complete(featureStatus);
        });
      });

      return completer.future;
    } else {
      _log.info("Skipping feature $name due to tags not matching");
      featureStatus.skipped = true;

      return new Future.value(featureStatus);
    }
  }

  /**
   * Converts to printable format
   */
  String toString() {
    return "$name ${tags == null ? "" : tags}\n $background \n$scenarios";
  }
}


class Scenario {
  String name;

  List<String> tags;

  Scenario background;

  List<Step> steps = [];
  GherkinTable examples = new GherkinTable();

  Location location;

  Scenario(this.name, this.location);

  Future<ScenarioStatus> execute(Map<RegExp, Function> stepRunners) {
    if (examples._table.isEmpty) {
      examples._table.add({});
    }
    if (background != null) {
      background.execute(stepRunners);
    }

    var scenarioStatus = new ScenarioStatus()
      ..scenario = this;

    var tableIter = examples._table.iterator;
    while (tableIter.moveNext()) {
      var row = tableIter.current;
      scenarioStatus.buffer.write("\n\tScenario: $name");
      scenarioStatus.buffer.writeln("$location", color: 'gray');

      var iter = steps.iterator;
      while (iter.moveNext()) {
        var step = iter.current;
        var stepStatus = new StepStatus()
          ..step = step;

        var found = stepRunners.keys.firstWhere((key) => key.hasMatch(step.verbiage), orElse: () => null);

        if (found == null) {
          stepStatus.defined = false;
          stepStatus.writeIntoBuffer();
          scenarioStatus.buffer.merge(stepStatus.buffer);
          scenarioStatus.undefinedSteps.add(stepStatus);
          continue;
        }

        var match = found.firstMatch(step.verbiage);

        // (unrelated) Notes :
        // The FeatureContext class approach for stepdefs makes sense :
        // - you implement methods and wrap them with annotations.
        // - you use properties as you want as context shared by steps.
        // Also, @Given @When @Then decorators ?

        // Parameters from Regex
        // Todo: num.parse() when it makes sense ?
        var params = [];
        for (var i = 1; i <= match.groupCount; i++) {
          params.add(match[i]);
        }
        // PyString
        if (step.pyString != null) {
          params.add(step.pyString);
        }
        // Ctx
        // About ctx and params... merge them ?
        var ctx = {
            "table": step.table
        };

        try { // to run the step
          stepRunners[found](ctx, params, row);
        } catch (e, s) {
          _log.debug("Step failed: $step");
          if (e is Exception) {
            stepStatus.error = e;
          } else {
            stepStatus.error = new Exception(e.toString());
          }
          stepStatus.trace = s.toString();
          scenarioStatus.failedSteps.add(stepStatus);
        } finally {
          stepStatus.writeIntoBuffer();
          scenarioStatus.buffer.merge(stepStatus.buffer);
        }

      }
    }

    return new Future.value(scenarioStatus);
  }

  void addStep(Step step) {
    steps.add(step);
  }

  String toString() {
    return "${tags == null ? "" : tags} $name $steps \nExamples: $examples";
  }
}

class Step {
  String verbiage;
  String pyString;
  GherkinTable table = new GherkinTable();
  Location location;

  Step(this.verbiage, this.location);

  String toString() {
    if (pyString != null) {
      return "$verbiage\n\"\"\"\n$pyString\"\"\"\n$table";
    } else {
      return "$verbiage $table";
    }
  }

  String get boilerplate {
    var matchString = verbiage.replaceAll(new RegExp("\".+?\""), "\\\"(\\\\w+?)\\\"");
    var columnsVerbiage = table.length > 0 ? ", { ${table.names.join(", ")} }" : "";
    return ("\n@StepDef(\"$matchString\")\n${_generateFunctionName()}(ctx, params$columnsVerbiage) {\n  // todo \n}\n");
  }

  String _generateFunctionName() {
    var chunks = verbiage.replaceAll(new RegExp("\""), "").replaceAll(new RegExp("[<>]"), r"$").split(new RegExp(" "));
    var end = chunks.length > 3 ? 4 : chunks.length;
    return chunks.sublist(0, end).join("_").toLowerCase();
  }
}

class StepDef {
  final String verbiage;
  const StepDef(this.verbiage);
}


/// Feedback from one feature's execution.
class FeatureStatus {
  /// The feature that generated this status information.
  Feature feature;
  /// Was this [feature] [skipped] because of mismatching tags ?
  bool skipped = false;
  /// Has the [feature] [passed] ? (all scenarios passed)
  bool get passed => failedScenariosCount == 0;
  /// Has the [feature] [failed] ? (any scenario failed)
  bool get failed => failedScenariosCount > 0;
  /// Scenarios. (could also add zapped scenarios)
  List<ScenarioStatus> passedScenarios = [];
  List<ScenarioStatus> failedScenarios = [];
  int get passedScenariosCount => passedScenarios.length;
  int get failedScenariosCount => failedScenarios.length;

  List<StepStatus> get undefinedSteps {
    List<StepStatus> list = [];
    for (ScenarioStatus s in passedScenarios) {
      list.addAll(s.undefinedSteps);
    }
    for (ScenarioStatus s in failedScenarios) {
      list.addAll(s.undefinedSteps);
    }
    return list;
  }

  /// Text buffer for the feature runner to write in.
  /// Should contain all lines added by the feature and its scenarios.
  ResultBuffer buffer;

  FeatureStatus() {
    buffer = new ColoredFragmentsBuffer();
  }
}


/// Feedback from one scenario's execution.
class ScenarioStatus {
  /// The [scenario] that generated this status information.
  Scenario scenario;
  /// Was the [scenario] [skipped] because of mismatching tags ?
  bool skipped = false;
  /// Has the [scenario] [passed] ? (all steps passed)
  bool get passed => failedStepsCount == 0;
  /// Has the [scenario] [failed] ? (any step failed)
  bool get failed => failedStepsCount > 0;
  /// Steps.
  List<Step> passedSteps = [];
  List<Step> failedSteps = [];
  List<Step> undefinedSteps = [];
  int get passedStepsCount => passedSteps.length;
  int get failedStepsCount => failedSteps.length;
  int get undefinedStepsCount => undefinedSteps.length;

  /// Text buffer for the scenario runner to write in.
  /// Should contain all lines added by steps during the scenario's execution.
  ResultBuffer buffer;

  ScenarioStatus() {
    buffer = new ColoredFragmentsBuffer();
  }
}


/// Feedback from one step's execution.
class StepStatus {
  /// The [step] that generated this status information.
  Step step;
  /// Has the [step] [passed] ?
  bool get passed => error == null;
  /// Has the [step] [failed] ?
  bool get failed => error != null;
  /// Has the [step] [crashed] ?
  bool get crashed => error != null && !(error is AssertionError);
  /// Was the [step] [defined] ?
  bool defined = true;

  /// The [error] raised on failure.
  Exception error;
  /// The stack [trace] on failure.
  String trace;
  //StackTrace trace; // Illegal argument in isolate message : (object is a stacktrace)

  /// Text buffer for the step runner to write in.
  /// Should contain all lines added by the step's execution, and only them.
  ResultBuffer buffer;

  StepStatus() {
    buffer = new ColoredFragmentsBuffer();
  }

  void writeIntoBuffer() {
    var color = "green";
    var extra = "";
    if (!defined) {
      color = "yellow";
    }
    if (failed) {
      color = "red";
      extra = "\n${error}\n${trace}";
    }
    if (step.pyString != null) {
      buffer.writeln("\t\t${step.verbiage}\n\"\"\"\n${step.pyString}\"\"\"$extra", color: color);
    } else {
      buffer.write("\t\t${step.verbiage}", color: color);
      buffer.write("\t${step.location}", color: 'gray');
      buffer.writeln(extra, color: color);
    }
  }
}


class Location {
  String srcFilePath;
  int srcLineNumber;

  Location(this.srcFilePath, this.srcLineNumber);

  String toString() {
    return " # $srcFilePath:$srcLineNumber";
  }
}


class GherkinTable {
  List<String> _columnNames = [];
  List<Map> _table = [];

  int get length => _table.length;

  List<String> get names => _columnNames;

  void addRow(row) {
    if (_columnNames.isEmpty) {
      _columnNames.addAll(row);
    } else {
      _table.add(new Map.fromIterables(_columnNames, row));
    }
  }

  String toString() {
    return _table.toString();
  }
}

class StepDefUndefined implements Exception {}

final _NOOP = new Scenario("NOOP", new Location("", -1));