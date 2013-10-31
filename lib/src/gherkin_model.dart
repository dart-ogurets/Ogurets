part of dherkin;

class Feature {
  String name;
  List<String> tags;
  List<Scenario> scenarios = [];

  Feature(this.name);

  String toString() {
    return "$name $tags\n $scenarios";
  }
}

class Scenario {
  String name;
  List<String> tags;
  List<String> steps = [];

  Scenario(this.name);

  String toString() {
    return "$tags $name $steps";
  }
}
