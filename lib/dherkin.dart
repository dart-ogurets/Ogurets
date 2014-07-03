library dherkin;

import "dart:io";
import "dart:async";

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
 *
 * We should continue on the OO design pattern and make a DherkinRunner or something.
 */
Future run(args) {
  var sw = new Stopwatch()..start();
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

  RunStatus runStatus = new RunStatus();

  var featureFutures = [];
  return findStepRunners().then((stepRunners) {
    Completer allDone = new Completer();
    Future.forEach(featureFiles, (filePath) {
      Completer c = new Completer();
      new File(filePath).readAsLines().then((List<String> contents) {
        worker.handle(new GherkinParserTask(contents, filePath)).then((feature) {
          Future f = feature.execute(stepRunners, runTags: runTags, worker: worker, debug: options["debug"]);
          f.then((FeatureStatus featureStatus){
            if (featureStatus.failed) {
              runStatus.failedFeatures.add(featureStatus);
            } else {
              runStatus.passedFeatures.add(featureStatus);
            }
            _buffer.merge(featureStatus.buffer);
            _buffer.flush();
          });
          featureFutures.add(f);
          c.complete();
        });
      });
      return c.future;
    }).whenComplete(() => Future.wait(featureFutures).whenComplete((){
      // Tally the failed / passed features
      _buffer.writeln("==================");
      if (runStatus.passedFeaturesCount > 0) {
        _buffer.writeln("Features passed: ${runStatus.passedFeaturesCount}", color: "green");
      }
      if (runStatus.failedFeaturesCount > 0) {
        _buffer.writeln("Features failed: ${runStatus.failedFeaturesCount}", color: "red");
      }
      _buffer.flush();
      // Tally the missing stepdefs boilerplate
      _buffer.write(runStatus.boilerplate, color: "yellow");
      _buffer.write("----------------------------------------------------");
      _buffer.write("\nExecuted ${runStatus.passedFeaturesCount + runStatus.failedFeaturesCount} features in ${sw.elapsed.inSeconds} seconds\n", color: 'white');
      _buffer.write("----------------------------------------------------");
      _buffer.flush();
      // Close the runner
      worker.close();
      allDone.complete(runStatus);
    }));

    return allDone.future;
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

