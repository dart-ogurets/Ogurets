library dherkin;

import "dart:io";
import "dart:async";
import "dart:mirrors";

import 'package:args/args.dart';
import "package:log4dart/log4dart.dart";
import "package:worker/worker.dart";

import "dherkin_base.dart";
export "dherkin_base.dart";


Logger _log = LoggerFactory.getLogger("dherkin");
ResultBuffer _buffer = new ConsoleBuffer();


/**
 * Runs specified gherkin files with provided flags.
 * [args] may be a list of filepaths.
 */
Future run(args) {
  var options = _parseArguments(args);

  if (!options["debug"]) {  // unsure about effect of this.
    LoggerFactory.config[".*"].debugEnabled = false;
  }

  int okScenariosCount = 0;
  int koScenariosCount = 0;

  var runTags = [];
  if (options["tags"] != null) {
    runTags = options["tags"].split(",");
  }

  var worker = new Worker(spawnLazily: false, poolSize: Platform.numberOfProcessors);

  var featureFiles = options.rest;

  var futures = [];
  return findStepRunners().then((stepsRunners) {
    return Future.forEach(featureFiles, (filePath) {
      Completer c = new Completer();
      new File(filePath).readAsLines().then((List<String> contents) {
        return worker.handle(new GherkinParserTask(contents)).then((featur) {
          c.complete();
          return futures.add(featur.execute(worker, _buffer, stepsRunners, runTags));
        });
      });
      return c.future;
    }).whenComplete(() => Future.wait(futures).whenComplete(() => worker.close()));

//    Future.forEach(options.rest, (filePath) {
//      Completer c = new Completer();
//      new File(filePath).readAsLines().then((List<String> contents) {
//        var modelCreator = parser.parse(contents);
//        modelCreator.then((feature) {
//          if(doesTagsMatch(feature.tags, runTags)) {
//            _log.debug("Executing: $feature");
//            feature.execute(writer, stepsRunners, runTags).whenComplete(() {
//              c.complete(feature);
//              okScenariosCount += feature.okScenariosCount;
//              koScenariosCount += feature.koScenariosCount;
//              return new Future(() => writer.flush());
//            });
//          } else {
//            _log.debug("Skipping: $feature due to no tags matching");
//          }
//        });
//      });
//      return c.future;
//    }).then((_){
//      if (okScenariosCount > 0) {
//        writer.write("\n$okScenariosCount scenario(s) ran successfully.", color: "green");
//      }
//      if (koScenariosCount > 0) {
//        writer.write("\n$koScenariosCount scenario(s) failed.", color: "red");
//      }
//    });
  });

//  if (okScenariosCount > 0) {
//    _writer.write("\n$okScenariosCount scenario(s) ran successfully.", color: "green");
//  }
//
//  if (koScenariosCount > 0) {
//    _writer.write("\n$koScenariosCount scenario(s) failed.", color: "red");
//  }
}


/**
 * Parses command line arguments.
 */
ArgResults _parseArguments(args) {
  var argParser = new ArgParser();
  argParser.addFlag('junit', defaultsTo: true); // this is not used ?
  argParser.addFlag('debug', defaultsTo: true);
  argParser.addOption("tags");
  return argParser.parse(args);
}

