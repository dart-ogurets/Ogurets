import "dart:io";
import "dart:async";
import "dart:mirrors";
import "../lib/dherkin.dart";


RegExp tagsPattern = new RegExp(r"(@[^@\r\n\t ]+)");
RegExp featurePattern = new RegExp(r"Feature\s*:\s*(.+)");
RegExp scenarioPattern = new RegExp(r"Scenario\s*:\s*(.+)");

void main() {
  File file = new File("example/gherkin/test_feature.feature");

  var feature;
  var currentScenario;
  file.readAsLines().then((List<String> contents) {
    var tags = [];

    var lineIter = contents.iterator;

    while (lineIter.moveNext()) {
      var line = lineIter.current;

      var iter = tagsPattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        print(match.group(1));
        tags.add(match.group(1));
      }

      iter = featurePattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        print(match.group(1));
        feature = new Feature(match.group(1));
        feature.tags = tags;
        tags = [];
      }

      iter = scenarioPattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        print(match.group(1));
        currentScenario = new Scenario(match.group(1));
        currentScenario.tags = tags;
        feature.scenarios.add(currentScenario);
        tags = [];
      }

    }

  }).whenComplete(() {
    print(feature);
  });

//  Locate stepdefs
//  Output verbiage for missing stepdefs
  }
  @StepDef("Aloha")
  step1() {

  }

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

  Scenario(this.name);

  String toString() {
    return "$name $tags";
  }

}