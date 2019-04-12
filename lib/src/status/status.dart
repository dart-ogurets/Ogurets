part of dherkin_core3;

class BufferedStatus {
  /// Text buffer for the runner to write in.
  ResultBuffer buffer;

  BufferedStatus() {
    buffer = new ColoredFragmentsBuffer();
  }
}

/// A run/feature/scenario status of multiple steps, maybe with undefined ones.
abstract class StepsExecutionStatus extends BufferedStatus {
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
  /// Undefined steps
  List<StepStatus> get undefinedSteps {
    List<StepStatus> list = [];
    for (FeatureStatus feature in features) {
      list.addAll(feature.undefinedSteps);
    }
    return list;
  }
  int get undefinedStepsCount => undefinedSteps.length;
  /// Failures
  List<StepFailure> get failures {
    List<StepFailure> _failures = new List();
    for (FeatureStatus feature in features) {
      if (feature.failed) {
        _failures.addAll(feature.failures);
      }
    }
    return _failures;
  }
  String get trace => failures.fold("", (p, n) => "$p${n.error.toString()}\n${n.trace}\n");
  String get error => failures.fold("", (p, n) => "$p${n.error.toString()}\n");

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
    for (ScenarioStatus senario in scenarios) {
      list.addAll(senario.undefinedSteps);
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
  String get error => failures.fold("", (p, n) => "$p${n.error.toString()}\n");

  FeatureStatus() : super();
}


/// Feedback from one scenario's execution.
class ScenarioStatus extends StepsExecutionStatus {
  /// The [scenario] that generated this status information.
  /// If this ScenarioStatus is one of a Background, it is here.
  Scenario scenario;
  /// An optional [background] that enriched this status information.
  /// Backgrounds have no [background].
  Background background;
  /// Was the [scenario] [skipped] because of mismatching tags ?
  bool skipped = false;
  /// Has the [scenario] [passed] ? (all steps passed)
  bool get passed => failedStepsCount == 0;
  /// Has the [scenario] [failed] ? (any step failed)
  bool get failed => failedStepsCount > 0;
  /// Steps.
  List<StepStatus> get steps {
    List<BufferedStatus> all = [];
    all.addAll(passedSteps);
    all.addAll(failedSteps);
    return all;
  }
  List<StepStatus> passedSteps = [];
  List<StepStatus> failedSteps = [];
  List<StepStatus> undefinedSteps = [];
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

  void mergeBackground(ScenarioStatus other, { isFirst: true }) {
    if (other.scenario is Background) {
      background = other.scenario;
      passedSteps.addAll(other.passedSteps);
      failedSteps.addAll(other.failedSteps);
      undefinedSteps.addAll(other.undefinedSteps);
      if (isFirst) {
        // If we write to background within the worker task
        // the others don't have the updated value,
        // so we use the parameter isFirst.
        // background.bufferIsMerged = true;
        buffer.merge(other.buffer);
      }
    } else {
      throw new Exception("$other is not a Background");
    }
  }
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

  StringBuffer out = new StringBuffer();

  StepStatus() : super();

  void writeIntoBuffer() {
    var color = "green";
    var failureMessage = "";

    if (!defined) {
      color = "yellow";
    }
    if (failed) {
      color = "red";
      failureMessage = "\n${failure.error}\n${failure.trace}";
    }
    if (step.pyString != null) {
      buffer.writeln("\t\t${step.verbiage}\n\"\"\"\n${step.pyString}\"\"\"$failureMessage", color: color);
    } else {
      buffer.write("\t\t${step.verbiage}", color: color);
      buffer.write("\t${step.location}", color: 'gray');

      if (!step.table.isEmpty) {
        buffer.write("\n${step.table.gherkinRows().join("\n")}", color: 'cyan');
      }

      if(out.isNotEmpty) {
        buffer.write("\n");
        buffer.write(out.toString());
      }

      buffer.writeln(failureMessage, color: color);
    }
  }
}
