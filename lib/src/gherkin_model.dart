part of dherkin;

class Feature {
  String name;

  List<String> tags;

  Scenario background = _NOOP;
  List<Scenario> scenarios = [];

  Feature(this.name);

  Future execute(executors) {
    _writer.write("Feature: $name");
    return Future.forEach(scenarios, ((Scenario scenario) {
      _log.debug("Expected tags: $_runTags.  Scenario tags: ${scenario.tags}");
      if(_tagsMatch(scenario.tags)) {
        _log.debug("Executing Scenario: $scenario");
        background.execute(executors);
        scenario.execute(executors);
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

  void execute(executors) {
    _writer.write("\n\tScenario: $name");
    var iter = steps.iterator;
    while (iter.moveNext()) {
      var step = iter.current;

      var runner = executors.locate(step.verbiage);

      var color = "green";
      var extra = "";
      try {
        runner({"table" : step.table});
      } on StepDefUndefined {
        color = "yellow";
      } catch(e, stack) {
        _log.debug("Step failed: $step");
        extra = "\n" + stack.toString();
        color = "red";
      } finally {
        _writer.write("\t\t${step.verbiage}$extra", color: color);
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
  GherkinTable table = new GherkinTable();

  Step(this.verbiage);

  String toString() {
    return "$verbiage $table";
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