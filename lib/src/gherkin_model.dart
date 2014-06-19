part of dherkin_base;

class Feature {
  static final Logger _log = LoggerFactory.getLogger("dherkin");

  String name;
  List<String> tags;

  Scenario background = _NOOP;
  List<Scenario> scenarios = [];

  int okScenariosCount = 0;
  int koScenariosCount = 0;

  Feature(this.name);

  Future execute(ResultWriter writer, Map<RegExp,Function> stepDefs, runTags) {
    writer.write("Feature: $name");
    return Future.forEach(scenarios, ((Scenario scenario) {
      _log.debug("Expected tags: $runTags.  Scenario tags: ${scenario.tags}");
      if(doesTagsMatch(scenario.tags, runTags)) {
        _log.debug("Executing Scenario: $scenario");
        background.execute(writer, stepDefs);
        scenario.execute(writer, stepDefs);
        if (scenario.hasFailed) {
          koScenariosCount++;
        } else {
          okScenariosCount++;
        }
      } else {
        _log.debug("Skipping Scenario: $scenario");
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

  bool hasFailed = false;

  Scenario(this.name);

  void execute(ResultWriter writer, Map<RegExp,Function> stepDefs) {
    if(examples._table.isEmpty) {
      examples._table.add({});
    }

    var tableIter = examples._table.iterator;
    while (tableIter.moveNext()) {
      var row = tableIter.current;
      writer.write("\n\tScenario: $name");
      var iter = steps.iterator;
      while (iter.moveNext()) {
        var step = iter.current;
        var found = stepDefs.keys.firstWhere((key) => key.hasMatch(step.verbiage), orElse: () => STEPDEF_NOTFOUND);

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
          writer.missingStepDef(step.verbiage, examples._columnNames);
        }

        var color = "green";
        var extra = "";

        var ctx = {"table":step.table};
        try {
          stepDefs[found](ctx,params, row);
        }
        on StepDefUndefined
        {
          color = "yellow";
        }
        catch(e, stack) {
          hasFailed = true;
          extra = "\n" + e.toString() + "\n" + stack.toString();
          color = "red";
        } finally {
          if (step.pyString != null) {
            writer.write("\t\t${step.verbiage}\n\"\"\"\n${step.pyString}\"\"\"$extra", color: color);
          } else {
            writer.write("\t\t${step.verbiage}$extra", color: color);
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
    if (pyString != null) {
      return "$verbiage\n\"\"\"\n$pyString\"\"\"\n$table";
    } else {
      return "$verbiage $table";
    }
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