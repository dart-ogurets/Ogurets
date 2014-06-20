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
          futures.add(feature.execute(_buffer, stepRunners, runTags: runTags, worker: worker));
          c.complete();
        });
      });
      return c.future;
    }).whenComplete(() => Future.wait(futures).whenComplete(() => worker.close()));
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

