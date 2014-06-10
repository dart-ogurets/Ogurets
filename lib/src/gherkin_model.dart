part of dherkin;

class Feature {
  String name;

  List<String> tags;

  Scenario background = _NOOP;
  List<Scenario> scenarios = [];

  Feature(this.name);

  Future execute() {
    _writer.write("Feature: $name");
    return Future.forEach(scenarios, ((Scenario scenario) {
      _log.debug("Expected tags: $_runTags.  Scenario tags: ${scenario.tags}");
      if(_tagsMatch(scenario.tags)) {
        _log.debug("Executing Scenario: $scenario");
        background.execute();
        scenario.execute();
      }
    }));
  }

  String toString() {
    return "$name ${tags == null ? "" : tags}\n $background \n$scenarios";
  }
}

class Scenario {
  String name;

  List<String> tags;

  List<Step> steps = [];
  GherkinTable examples = new GherkinTable();

  Scenario(this.name);

  void execute() {
    if(examples._table.isEmpty) {
      examples._table.add({});
    }

    var tableIter = examples._table.iterator;
    while (tableIter.moveNext()) {
      var row = tableIter.current;
      _writer.write("\n\tScenario: $name");
      var iter = steps.iterator;
      while (iter.moveNext()) {
        var step = iter.current;
        var found = _stepRunners.keys.firstWhere((key) => key.hasMatch(step.verbiage), orElse: () => _NOTFOUND);

        var match = found.firstMatch(step.verbiage);
        var params = [];
        if (match != null) {
          // Parameters from Regex
          for (var i = 1;i <= match.groupCount;i++) {
            params.add(match[i]);
          }
          // PyString
          if (step.pyString != null) {
            params.add(step.pyString);
          }

        } else {
          _writer.missingStepDef(step.verbiage, examples._columnNames);
        }

        var color = "green";
        var extra = "";

        var ctx = {"table":step.table};
        try {
          _stepRunners[found](ctx,params, row);
        }
        on StepDefUndefined
        {
          color = "yellow";
        }
        catch(e, stack) {
          _log.debug("Step failed: $step");
          _log.debug(e.toString());
          _log.debug(stack.toString());
          extra = "\n" + e.toString() + "\n" + stack.toString();
          color = "red";
        } finally {
          if (step.pyString != null) {
            _writer.write("\t\t${step.verbiage}\n\"\"\"\n${step.pyString}\"\"\"$extra", color: color);
          } else {
            _writer.write("\t\t${step.verbiage}$extra", color: color);
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

  Step(this.verbiage);

  String toString() {
    return "$verbiage $pyString $table";
  }
}

class GherkinTable {
  List<String> _columnNames = [];
  List<Map> _table = [];

  void addRow(row) {
    if(_columnNames.isEmpty) {
      _columnNames.addAll(row);
    }
    else {
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

class StepDefUndefined implements Exception {

}

final _NOOP = new Scenario("NOOP");