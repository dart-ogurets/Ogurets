library dherkin;

import "dart:io";

import 'package:args/args.dart';
import "package:logging/logging.dart";

import 'dherkin_core.dart';
export 'dherkin_core.dart';


ResultBuffer _buffer = new ConsoleBuffer(); // TODO instantiate based on args

/**
 * Runs specified gherkin files with provided flags.
 * [args] may be a list of filepaths.
 *
 * We should continue on the OO design pattern and make a DherkinRunner or something.
 */
run(args) async {
  var options = _parseArguments(args);

  // Use this to run with argument in IDE. Useful for debug.
  if (options.arguments == null || options.arguments.isEmpty) {
    var hardcodedArg = ['example/gherkin/test_feature.feature'];
    options = _parseArguments(hardcodedArg);
  }
  var debug = options["debug"];
  if(debug){
    Logger.root.level = Level.FINE;
  } else {
    Logger.root.level = Level.INFO;
  }

  List<String> runTags = [];
  if (options["tags"] != null) {
    runTags = options["tags"].split(",");
  }

  var featureFiles = options.rest;
  RunStatus runStatus = new RunStatus();

  var stepRunners = await findStepRunners();
  for (String filePath in featureFiles) {
    List<String> contents = await new File(filePath).readAsLines();
    Feature feature = await new GherkinParserTask(contents, filePath).execute();
    FeatureStatus featureStatus = await feature.execute(stepRunners, runTags: runTags, debug: debug);
    if (featureStatus.failed) {
      runStatus.failedFeatures.add(featureStatus);
    } else {
      runStatus.passedFeatures.add(featureStatus);
    }
    _buffer.merge(featureStatus.buffer);
    _buffer.flush();
  }
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
  _buffer.flush();
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