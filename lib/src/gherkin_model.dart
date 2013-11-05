part of dherkin;

class Feature {
  String name;

  List<String> tags;

  Scenario background = _NOOP;
  List<Scenario> scenarios = [];

  Feature(this.name);

  Future<String> execute(provider) {
    Completer comp = new Completer();
    var missingSteps = [];
    Future.forEach(scenarios, ((Scenario scenario) {
      missingSteps.addAll(background.execute(provider));
      var missing = scenario.execute(provider);
      missingSteps.addAll(missing);
    })).whenComplete(() {
      comp.complete(missingSteps);
    });

    return comp.future;
  }

  String toString() {
    return "$name ${tags == null ? "" : tags}\n $background \n$scenarios";
  }
}

class Scenario {
  String name;

  List<String> tags;

  List<Step> steps = [];
  List<Map> examples = [];

  Scenario(this.name);

  List<String> execute(provider) {
    var missingSteps = [];
    var iter = steps.iterator;
    while (iter.moveNext()) {
      var stepString = iter.current.verbiage;
      var step = provider.locate(stepString);

      try {
        step();
      } on StepDefUndefined {
        _log.warn("Undefinded step: $stepString");
        missingSteps.add(stepString);
      }
    }

    return missingSteps;
  }

  void addStep(Step step) {
    steps.add(step);
  }

  String toString() {
    return "${tags == null ? "" : tags} $name $steps";
  }
}

class Step {
  String verbiage;
  List<Map> table = [];

  Step(this.verbiage);

  String toString() {
    return verbiage;
  }
}

class StepDef {
  final String verbiage;

  const StepDef(this.verbiage);
}

class StepDefUndefined implements Exception {

}

final _NOOP = new Scenario("NOOP");