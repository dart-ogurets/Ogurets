library dherkin;

import "dart:io";
import "dart:async";
import "dart:mirrors";

import 'package:args/args.dart';
import "package:log4dart/log4dart.dart";
import "package:worker/worker.dart";

import 'dherkin_core.dart';
export 'dherkin_core.dart';


Logger _log = LoggerFactory.getLogger("dherkin");
ResultBuffer _buffer = new ConsoleBuffer(); // TODO instantiate based on args

/**
 * Runs specified gherkin files with provided flags.
 * [args] may be a list of filepaths.
 */
Future run(args) {
  var options = _parseArguments(args);

  LoggerFactory.config[".*"].debugEnabled = options["debug"];

  int okScenariosCount = 0;
  int koScenariosCount = 0;

  var runTags = [];
  if (options["tags"] != null) {
    runTags = options["tags"].split(",");
  }

  var worker = new Worker(spawnLazily: false, poolSize: Platform.numberOfProcessors);

  var featureFiles = options.rest;

  var futures = [];
  return findStepRunners().then((stepRunners) {
    return Future.forEach(featureFiles, (filePath) {
      Completer c = new Completer();
      new File(filePath).readAsLines().then((List<String> contents) {
        return worker.handle(new GherkinParserTask(contents, filePath)).then((feature) {
          Future f = feature.execute(stepRunners, runTags: runTags, worker: worker, debug: options["debug"]);
          f.then((FeatureStatus featureStatus){
            _buffer.merge(featureStatus.buffer);
            _buffer.flush();
            c.complete();
          });
          futures.add(f);
        });
      });
      return c.future;
    }).whenComplete(() => Future.wait(futures).whenComplete((){
      // tally the missing stepdefs
      List missingStepDefs = [];
      for (var f in futures) {
        f.then((FeatureStatus featureStatus){
          missingStepDefs.addAll(featureStatus.undefinedSteps);
        });
      }
      Future.wait(futures).whenComplete((){
        for (StepStatus s in missingStepDefs) {
          _buffer.write(s.step.boilerplate, color: "yellow");
        }
        _buffer.flush();
      });
      worker.close();
    }));
  });

}

/**
 * Parses command line arguments.
 */

ArgResults _parseArguments(args) {
  var argParser = new ArgParser();
  argParser.addFlag('debug', defaultsTo: false);
  argParser.addOption("tags");
  return argParser.parse(args);
}

