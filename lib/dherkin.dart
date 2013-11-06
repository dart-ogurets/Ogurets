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

ResultWriter _writer = new _ConsoleWriter();

var _runTags;

void run(args) {
  var options = _parseArguments(args);
  _runTags = options["tags"].split(",");

  // TODO re-init writer based on flags

  var scanner = new StepdefProvider();
  var parser = new GherkinParser();

  scanner.scan().then((executors) {
    options.rest.forEach((filePath) {
      var modelCreator = parser.parse(new File(filePath));

      modelCreator.then((feature) {
        if(_tagsMatch(feature.tags)) {
          _log.debug("Executing: $feature");
          feature.execute(executors).whenComplete(() => new Future(() => _writer.flush()));
        } else {
          _log.debug("Skipping: $feature due to no tags matching");
        }
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
  argParser.addOption("tags");
  ArgResults options = argParser.parse(args);
  return options;
}

bool _tagsMatch(tags) {
  return _runTags.isEmpty || tags.any((element) =>_runTags.contains(element));
}