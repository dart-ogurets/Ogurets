part of dherkin_core;

class ScenarioExecutionTask implements Task {

  Scenario scenario;
  ResultBuffer buffer = new ConsoleBuffer(); // TODO create appropriate type

  ScenarioExecutionTask(this.scenario);

  Future execute() {
    LoggerFactory.config[".*"].debugEnabled = false;  // TODO key off options
    Completer c = new Completer();
    // We cannot have stepDefs as injected dependency, (object is closure),
    // so we re-seek them in this task.
    findStepRunners().then((stepDefs) {
      scenario.execute(buffer, stepDefs);
      _log.debug("Done executing: ${scenario.name}");
      c.complete([buffer, scenario.hasFailed]);
    });

    return c.future;
  }
}

class Feature {

  String name;
  List<String> tags;

  Scenario background = _NOOP;
  List<Scenario> scenarios = [];

  Location location;

  int okScenariosCount = 0;
  int koScenariosCount = 0;

  Feature(this.name, this.location);

  Future execute(Worker worker, ResultBuffer buffer, runTags) {

    if (_tagsMatch(tags, runTags)) {
      buffer.write("\nFeature: $name");
      buffer.writeln("$location", color: 'gray');

      var completer = new Completer();
      var results = [];
      Future.forEach(scenarios, (Scenario scenario) {
        _log.debug("Requested tags: $runTags.  Scenario is tagged with: ${scenario.tags}");
        if (_tagsMatch(scenario.tags, runTags)) {
          _log.debug("Executing Scenario: $scenario");

          scenario.background = background;

          Future scenarioFuture = worker.handle(new ScenarioExecutionTask(scenario));

          scenarioFuture.then((output) {
            buffer.merge(output[0]);

            if (output[1]) {
              okScenariosCount++;
            } else {
              koScenariosCount++;
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
          buffer.writeln("-------------------");
          buffer.writeln("Scenarios passed: $okScenariosCount", color: 'green');

          if (koScenariosCount > 0) {
            buffer.writeln("Scenarios failed: $koScenariosCount", color: 'red');
          }

          buffer.flush();
          completer.complete();
        });
      });

      return completer.future;
    } else {
      _log.info("Skipping feature $name due to tags not matching");

      return new Future.value("NOOP");
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

  bool hasFailed = false;

  Location location;

  Scenario(this.name, this.location);

  void execute(ResultBuffer buffer, Map<RegExp, Function> stepDefs) {
    if (examples._table.isEmpty) {
      examples._table.add({});
    }

    if (background != null) {
      background.execute(buffer, stepDefs);
    }

    var tableIter = examples._table.iterator;
    while (tableIter.moveNext()) {
      var row = tableIter.current;
      buffer.write("\n\tScenario: $name");
      buffer.writeln("$location", color: 'gray');

      var iter = steps.iterator;
      while (iter.moveNext()) {
        var step = iter.current;
        var found = stepDefs.keys.firstWhere((key) => key.hasMatch(step.verbiage), orElse: () => _STEPDEF_NOTFOUND);

        var match = found.firstMatch(step.verbiage);
        var params = [];
        if (match != null) {
          // Parameters from Regex
          for (var i = 1; i <= match.groupCount; i++) {
            params.add(match[i]);
          }
          // PyString
          if (step.pyString != null) {
            params.add(step.pyString);
          }

        } else {
          buffer.missingStepDef(step.verbiage, examples._columnNames);
        }

        var color = "green";
        var extra = "";

        var ctx = {
            "table": step.table
        };
        try {
          stepDefs[found](ctx, params, row);
        } on StepDefUndefined catch(e) {
          color = "yellow";
        } catch (e, s) {
          hasFailed = true;
          _log.debug("Step failed: $step");
          extra = "\n$e\n$s";
          color = "red";
        } finally {
          if (step.pyString != null) {
            buffer.writeln("\t\t${step.verbiage}\n\"\"\"\n${step.pyString}\"\"\"$extra", color: color);
          } else {
            buffer.write("\t\t${step.verbiage}", color: color);
            buffer.write("\t${step.location}", color: 'gray');
            buffer.writeln(extra, color: color);
          }
        }
      }
    }
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

class StepDef {
  final String verbiage;
  const StepDef(this.verbiage);
}

class StepDefUndefined implements Exception {}

final _NOOP = new Scenario("NOOP", new Location("", -1));