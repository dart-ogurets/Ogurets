library dherkin_example;

import "dart:io";
import "dart:async";
import "dart:mirrors";
import "../lib/dherkin.dart";


void main() {
//  Locate stepdefs
  var scanner = new StepdefScanner();
  var parser = new GherkinParser();
  scanner.scan().then((stepRunners) {
    var future = parser.parse(new File("example/gherkin/test_feature.feature"));

    future.then((feature) {
      print("FFF: $feature");

      feature.scenarios.forEach((Scenario scenario) {
        Map ctx = {};
        scenario.steps.forEach((String stepString) {
          var step = stepRunners[stepString];

          if(step == null) {
            print("Undefinded step: $stepString");
          } else {
            step(ctx);
          }
        });
      });
    });
  });
}

//  Output verbiage for missing stepdefs

//***************
@StepDef("parser is working")
step1(ctx) {
  print("Компрессия! $ctx");
}