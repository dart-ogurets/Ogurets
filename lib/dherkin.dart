library dherkin;

import "dart:io";
import "dart:async";
import "dart:mirrors";

import 'package:args/args.dart';
import "package:log4dart/log4dart.dart";

part "src/gherkin_model.dart";
part "src/gherkin_parser.dart";
part 'src/stepdef_provider.dart';
part "src/outputter.dart";

Logger _log = LoggerFactory.getLogger("dherkin");

void run(args) {
  var options = _parseArguments(args);

  // TODO change to be flag driven
  var writer = new _ConsoleWriter();

  var scanner = new StepdefProvider();
  var parser = new GherkinParser();

  scanner.scan().then((stepRunners) {
    options.rest.forEach((filePath) {
      var modelCreator = parser.parse(new File(filePath));

      modelCreator.then((feature) {
        _log.debug("Executing: $feature");
        feature.execute(stepRunners).then((List<String> missingSteps) {
          throw missingSteps;
        }).catchError(writer.missingStepDefs, test: (e) => e is List);
      });
    });
  });
}

/**
* Parses command line arguments
*/
ArgResults _parseArguments(args) {
  var argParser = new ArgParser();
  argParser.addFlag('junit', defaultsTo: true);
  ArgResults options = argParser.parse(args);
  return options;
}

