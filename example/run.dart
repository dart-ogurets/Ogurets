library dherkin_example;

import "dart:io";
import "dart:async";
import "dart:mirrors";
import "../lib/dherkin.dart";

RegExp tagsPattern = new RegExp(r"(@[^@\r\n\t ]+)");
RegExp featurePattern = new RegExp(r"Feature\s*:\s*(.+)");
RegExp scenarioPattern = new RegExp(r"Scenario\s*:\s*(.+)");
RegExp stepPattern = new RegExp(r"(given|when|then|and|but)\s+(.+)", caseSensitive:false);

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

      iter = stepPattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        currentScenario.steps.add(match.group(2));
      }

    }

  }).whenComplete(() {
    print(feature);

    Map stepRunners = {};

    Future.forEach(currentMirrorSystem().libraries.values, (LibraryMirror lib) {
      return new Future.sync(() {
        Future.forEach(lib.functions.values, (MethodMirror mm) {
          return new Future.sync(() {
            var filteredMetadata = mm.metadata.where((InstanceMirror im) => im.reflectee is StepDef);
            Future.forEach(filteredMetadata, (InstanceMirror im) {
              print(mm.simpleName);
              print(im);
              print(im.reflectee);
              print(im.reflectee.verbiage);

              stepRunners[im.reflectee.verbiage] = () {
                lib.invoke(mm.simpleName, []);
              };
            });
          });
        });
      });
    }).whenComplete(() {
      var step1 = feature.scenarios.first.steps.first;
      stepRunners[step1]();
    });
  });

//  Locate stepdefs
//  Output verbiage for missing stepdefs
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
  List<String> steps = [];

  Scenario(this.name);

  String toString() {
    return "$tags $name $steps";
  }
}

//***************
@StepDef("parser is working")
step1() {
  print("Компрессия!");
}