part of dherkin_core;

class Feature {

  String name;
  List<String> tags;

  Scenario background;
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
      bool isFirstScenario = true;
      Future.forEach(scenarios, (Scenario scenario) {
        Completer scenarioIsDone = new Completer();
        _log.debug("Requested tags: $runTags.  Scenario is tagged with: ${scenario.tags}");
        if (_tagsMatch(scenario.tags, runTags)) {
          _log.debug("Executing Scenario: $scenario");

          scenario.background = background;

          Future scenarioFuture;
          if (worker != null) {
            // the Task will re-fetch the stepRunners, as we can't send them here.
            scenarioFuture = worker.handle(new ScenarioExecutionTask(scenario, isFirst: isFirstScenario, debug: debug));
          } else {
            scenarioFuture = scenario.execute(stepRunners, isFirstOfFeature: isFirstScenario);
          }

          isFirstScenario = false;

          scenarioFuture.then((ScenarioStatus scenarioStatus) {

            featureStatus.buffer.merge(scenarioStatus.buffer);

            if (scenarioStatus.failed) {
              featureStatus.failedScenarios.add(scenarioStatus);
            } else {
              featureStatus.passedScenarios.add(scenarioStatus);
            }

            scenarioIsDone.complete(featureStatus);

          }).catchError((e, s) {
            _log.debug("ERROR $e \n $s");
          });

          results.add(scenarioFuture);
        } else {
          _log.debug("Skipping Scenario: $scenario");
        }

        return scenarioIsDone.future;

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


class Background extends Scenario {
  // todo: Fetch this from GherkinVocabulary or something
  String gherkinKeyword = "Background";
  //bool bufferIsMerged = false;

  Background(name, location) : super (name, location);
}


class Scenario {
  // todo: Fetch this from GherkinVocabulary or something
  String gherkinKeyword = "Scenario";

  String name;

  List<String> tags;

  Scenario background;

  List<Step> steps = [];
  GherkinTable examples = new GherkinTable();

  Location location;

  Scenario(this.name, this.location);

  /// Will execute the background and the scenario.
  /// If this scenario has an example table, it will execute all the generated scenarios,
  /// each with its own background, but background will be added to this scenario's buffer only once.
  Future<ScenarioStatus> execute(Map<RegExp, Function> stepRunners, { isFirstOfFeature: true }) {
    Completer allDone = new Completer();
    var scenarioStatus = new ScenarioStatus()
      ..scenario = this
      ..background = this.background;

    List<Future<ScenarioStatus>> subScenarioFutures = [];

    if (examples._table.isEmpty) {
      examples._table.add({});
    }

    Future.forEach(examples, (Map example) {
      Future subScenarioFuture = _executeSubScenario(scenarioStatus, example, stepRunners, isFirstOfFeature: isFirstOfFeature);
      subScenarioFutures.add(subScenarioFuture);
      return subScenarioFuture;
    }).whenComplete((){
      if(!examples.names.isEmpty) {
        scenarioStatus.buffer.writeln("\t  Examples: ", color: 'cyan');
        var counter = 0;
        examples.gherkinRows().forEach((row) {
          scenarioStatus.buffer.writeln(row, color: counter == 0 ? 'magenta' : 'green');
          counter++;
        });
      }

      allDone.complete(scenarioStatus);
    });

    return allDone.future;
  }

  void addStep(Step step) {
    steps.add(step);
  }

  String toString() {
    return "${tags == null ? "" : tags} $name $steps \nExamples: $examples";
  }

  Future<ScenarioStatus> _executeSubScenario(ScenarioStatus scenarioStatus, exampleRow, stepRunners, {isFirstOfFeature: true}) {
    Completer allDone = new Completer();

    Future<ScenarioStatus> backgroundStatusFuture;
    if (background != null) {
      backgroundStatusFuture = background.execute(stepRunners);
    } else {
      backgroundStatusFuture = new Future(()=>null);
    }

    backgroundStatusFuture.then((ScenarioStatus backgroundStatus) {

      if (backgroundStatus != null) {
        scenarioStatus.mergeBackground(backgroundStatus, isFirst: isFirstOfFeature);
      }

      scenarioStatus.buffer.write("\n\t${gherkinKeyword}: $name");
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

        // Parameters from Regex
        var params = [];
        for (var i = 1; i <= match.groupCount; i++) {
          params.add(Step.unserialize(match.group(i)));
        }
        // PyString
        if (step.pyString != null) {
          params.add(step.pyString);
        }

        if(!step.table.empty) {
          exampleRow["table"] = step.table;
        } else {
          exampleRow.remove("table");
        }

        try { // to actually run the step
          stepRunners[found](params, exampleRow);
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

      allDone.complete(scenarioStatus);
    });

    return allDone.future;
  }
}

class Step {
  String verbiage;
  String pyString;
  Scenario scenario;
  GherkinTable table = new GherkinTable();
  Location location;

  String get boilerplate => _generateBoilerplate();

  Step(this.verbiage, this.location, this.scenario);

  String toString() {
    if (pyString != null) {
      return "$verbiage\n\"\"\"\n$pyString\"\"\"\n$table";
    } else {
      return "$verbiage $table";
    }
  }

  /// Unserializes if int or num, and leaves as-is if neither.
  /// see https://github.com/dkornishev/dherkin/issues/27
  static dynamic unserialize(String parameter) {
    var unserialized = parameter;
    var test = null;
    // Int ?
    try { test = int.parse(parameter); }
    on FormatException catch (_) {}
    if (test != null) unserialized = test;
    // Num ?
    try { test = num.parse(parameter); }
    on FormatException catch (_) {}
    if (test != null) unserialized = test;


    return unserialized;
  }

  String _generateBoilerplate() {
    var matchString = verbiage.replaceAll(new RegExp("\".+?\""), "\\\"(\\\\w+?)\\\"");

    var params = "";
    var counter = 1;
    "w\+\?".allMatches(matchString).forEach((_) {
      params+="arg$counter,";
      counter++;
    });

    params = params.replaceAll(new RegExp(",\$"), "");

    var columnsVerbiage = scenario.examples.length > 1 ? "{ ${scenario.examples.names.join(", ")} ${!table.empty ? ", table" : ""} }" : "";
    var tableVerbiage = columnsVerbiage.isEmpty && !table.empty ? "${!params.isEmpty && columnsVerbiage.isEmpty ? "," : ""}{table}" : "";
    var separator = !params.isEmpty && !columnsVerbiage.isEmpty ? ", " : "";
    return ("\n@StepDef(\"$matchString\")\n${_generateFunctionName()}($params$separator$columnsVerbiage$tableVerbiage) {\n  // todo \n}\n");
  }

  String _generateFunctionName() {
    var chunks = verbiage.replaceAll(new RegExp("\""), "").replaceAll(new RegExp("[<>]"), r"$").split(new RegExp(" "));
    var end = chunks.length > 4 ? 5 : chunks.length;
    return chunks.sublist(0, end).join("_").toLowerCase();
  }
}

class GherkinTable extends IterableBase {

  final String _SPACER = "\t\t  ";

  List<String> _columnNames = [];
  List<Map> _table = [];

  Iterator get iterator => _table.iterator;

  int get length => _table.length;

  bool get empty => _table.isEmpty;

  List<String> get names => _columnNames;

  void addRow(row) {
    if (_columnNames.isEmpty) {
      _columnNames.addAll(row);
    } else {
      _table.add(new Map.fromIterables(_columnNames, row));
    }
  }

  /**
   * Gherkin table
   */
  String gherkinRows() {
    var rows = [];

    if(!_table.isEmpty) {
      rows.add("$_SPACER|${_columnNames.join(" | ")}|");

      for(var row in _table) {
        rows.add("$_SPACER|${row.values.join(" | ")}|");
      }
    }

    return rows;
  }

  String toString() {
    return _table.toString();
  }
}
