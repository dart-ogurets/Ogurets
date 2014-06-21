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
        var params = [];
        for (var i = 1; i <= match.groupCount; i++) {
          params.add(step.unserialize(match[i]));
        }
        // PyString
        if (step.pyString != null) {
          params.add(step.pyString);
        }
        // Ctx
        // About ctx and params... let's merge them ?
        var ctx = {
            "table": step.table
        };

        try { // to actually run the step
          stepRunners[found](ctx, params, row);
        } catch (e, s) {
          _log.debug("Step failed: $step");
          var failure = new StepFailure();
          if (e is Exception) {
            failure.error = e;
          } else {
            failure.error = new Exception(e.toString());
          }
          failure.trace = s.toString();
          stepStatus.failure = failure;
          scenarioStatus.failedSteps.add(stepStatus);
        } finally {
          if (!stepStatus.failed) {
            scenarioStatus.passedSteps.add(stepStatus);
          }
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

  String get boilerplate => _generateBoilerplate();

  Step(this.verbiage, this.location);

  String toString() {
    if (pyString != null) {
      return "$verbiage\n\"\"\"\n$pyString\"\"\"\n$table";
    } else {
      return "$verbiage $table";
    }
  }

  dynamic unserialize(String parameter) {
    var unserialized = parameter;
    // Int ?
    try { unserialized = int.parse(parameter); }
    on FormatException catch (_) {}
    // Num ?
    try { unserialized = num.parse(parameter); }
    on FormatException catch (_) {}

    return unserialized;
  }

  String _generateBoilerplate() {
    var matchString = verbiage.replaceAll(new RegExp("\".+?\""), "\\\"(\\\\w+?)\\\"");
    var columnsVerbiage = table.length > 0 ? ", { ${table.names.join(", ")} }" : "";
    return ("\n@StepDef(\"$matchString\")\n${_generateFunctionName()}(ctx, params$columnsVerbiage) {\n  // todo \n}\n");
  }

  String _generateFunctionName() {
    var chunks = verbiage.replaceAll(new RegExp("\""), "").replaceAll(new RegExp("[<>]"), r"$").split(new RegExp(" "));
    var end = chunks.length > 4 ? 5 : chunks.length;
    return chunks.sublist(0, end).join("_").toLowerCase();
  }
}


class StepDef {
  final String verbiage;
  const StepDef(this.verbiage);
}


class BufferedStatus {
  /// Text buffer for the runner to write in.
  ResultBuffer buffer;

  BufferedStatus() {
    buffer = new ColoredFragmentsBuffer();
  }
}

/// A run/feature/scenario status of multiple steps, maybe with undefined ones.
class StepsExecutionStatus extends BufferedStatus {
  /// Undefined steps.
  List<StepStatus> get undefinedSteps;
  /// A [boilerplate] (in Dart) of [undefinedSteps].
  String get boilerplate => _generateBoilerplate();

  String _generateBoilerplate() {
    String bp = '';
    List<Step> uniqueSteps = [];
    for (StepStatus stepStatus in this.undefinedSteps) {
      if (null == uniqueSteps.firstWhere((Step s) => s.verbiage == stepStatus.step.verbiage, orElse: ()=>null)) {
        uniqueSteps.add(stepStatus.step);
      }
    }
    for (Step step in uniqueSteps) {
      bp += step.boilerplate;
    }

    return bp;
  }

  StepsExecutionStatus()  : super();
}


/// Feedback from a run of one or more features
class RunStatus extends StepsExecutionStatus {

  /// Has the run [passed] ? (all features passed)
  bool get passed => failedFeaturesCount == 0;
  /// Has the run [failed] ? (any feature failed)
  bool get failed => failedFeaturesCount > 0;

  /// Features. (could also add skipped features)
  int get passedFeaturesCount => passedFeatures.length;
  int get failedFeaturesCount => failedFeatures.length;
  List<FeatureStatus> passedFeatures = [];
  List<FeatureStatus> failedFeatures = [];
  List<FeatureStatus> get features {
    List<FeatureStatus> all = [];
    all.addAll(passedFeatures);
    all.addAll(failedFeatures);
    return all;
  }



  RunStatus() : super();
}


/// Feedback from one feature's execution.
class FeatureStatus extends StepsExecutionStatus {
  /// The feature that generated this status information.
  Feature feature;
  /// Was the whole [feature] [skipped] because of mismatching tags ?
  /// It does not care about internal scenario skipping.
  /// idea: if all scenarios are individually skipped, mark feature as skipped ?
  bool skipped = false;
  /// Has the [feature] [passed] ? (all scenarios passed)
  bool get passed => failedScenariosCount == 0;
  /// Has the [feature] [failed] ? (any scenario failed)
  bool get failed => failedScenariosCount > 0;
  /// Scenarios. (could also add skipped scenarios)
  List<ScenarioStatus> get scenarios {
    List<ScenarioStatus> all = [];
    all.addAll(passedScenarios);
    all.addAll(failedScenarios);
    return all;
  }
  List<ScenarioStatus> passedScenarios = [];
  List<ScenarioStatus> failedScenarios = [];
  int get passedScenariosCount => passedScenarios.length;
  int get failedScenariosCount => failedScenarios.length;
  /// Undefined steps
  List<StepStatus> get undefinedSteps {
    List<StepStatus> list = [];
    for (ScenarioStatus s in scenarios) {
      list.addAll(s.undefinedSteps);
    }
    return list;
  }
  int get undefinedStepsCount => undefinedSteps.length;
  /// Failures
  List<StepFailure> get failures {
    List<StepFailure> _failures = new List();
    for (ScenarioStatus scenario in scenarios) {
      if (scenario.failed) {
        _failures.addAll(scenario.failures);
      }
    }
    return _failures;
  }
  String get trace => failures.fold("", (p, n) => "$p${n.error.toString()}\n${n.trace}\n");

  FeatureStatus() : super();
}


/// Feedback from one scenario's execution.
class ScenarioStatus extends StepsExecutionStatus {
  /// The [scenario] that generated this status information.
  Scenario scenario;
  /// Was the [scenario] [skipped] because of mismatching tags ?
  bool skipped = false;
  /// Has the [scenario] [passed] ? (all steps passed)
  bool get passed => failedStepsCount == 0;
  /// Has the [scenario] [failed] ? (any step failed)
  bool get failed => failedStepsCount > 0;
  /// Steps.
  List<StepStatus> get steps {
    List<ScenarioStatus> all = [];
    all.addAll(passedSteps);
    all.addAll(failedSteps);
    return all;
  }
  List<Step> passedSteps = [];
  List<Step> failedSteps = [];
  List<Step> undefinedSteps = [];
  int get passedStepsCount => passedSteps.length;
  int get failedStepsCount => failedSteps.length;
  int get undefinedStepsCount => undefinedSteps.length;

  List<StepFailure> get failures {
    List<StepFailure> _failures = new List();
    for (StepStatus stepStatus in steps) {
      if (stepStatus.failed) {
        _failures.add(stepStatus.failure);
      }
    }
    return _failures;
  }

  ScenarioStatus() : super();
}


/// Feedback from one step's execution.
class StepStatus extends BufferedStatus {
  /// The [step] that generated this status information.
  Step step;
  /// Has the [step] [passed] ?
  bool get passed => failure == null;
  /// Has the [step] [failed] ?
  bool get failed => failure != null;
  /// Has the [step] [crashed] ?
  bool get crashed => failure != null && !(failure is AssertionError);
  /// Was the [step] [defined] ?
  bool defined = true;

  /// A possible [failure].
  StepFailure failure;

  StepStatus() : super();

  void writeIntoBuffer() {
    var color = "green";
    var extra = "";
    if (!defined) {
      color = "yellow";
    }
    if (failed) {
      color = "red";
      extra = "\n${failure.error}\n${failure.trace}";
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

class StepFailure {
  Exception error;
  String trace; // Note: StackTrace yields Illegal argument in isolate message.
  // maybe Location, too ?
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