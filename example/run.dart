library dherkin_example;

import "dart:io";
import "dart:async";
import "dart:mirrors";
import "../lib/dherkin.dart";

void main() {
  var scanner = new StepdefScanner();
  var parser = new GherkinParser();
  scanner.scan().then((stepRunners) {
    var future = parser.parse(new File("example/gherkin/test_feature.feature"));

    future.then((feature) {

      var missingSteps = "";

      Future.forEach(feature.scenarios, ((Scenario scenario) {
        Map ctx = {};
        scenario.steps.forEach((String stepString) {
          var step = stepRunners[stepString];

          if(step == null) {
            print("Undefinded step: $stepString");
            var chunks = stepString.replaceAll(new RegExp("\""), "").split(new RegExp(" "));
            var end = chunks.length > 2 ? 3 : chunks.length;
            var functionName = chunks.sublist(0, end).join("_").toLowerCase();
            missingSteps += "\n@StepDef(\"$stepString\")\n$functionName(ctx) {\n// todo \n}\n";
          } else {
            step(ctx);
          }
        });
      })).whenComplete(() => print(missingSteps));
    });
  });
}


//***************
@StepDef("parser is working")
step1(ctx) {
  print("Компрессия! $ctx");
}

@StepDef("I run dherkin")
i_run_dherkin(ctx) {
  print("УРА!");
}