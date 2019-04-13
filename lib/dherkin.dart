library dherkin3;

import "dart:io";

import 'package:args/args.dart';
import "package:logging/logging.dart";
import "dart:mirrors";

import 'dherkin_core.dart';
export 'dherkin_core.dart';


ResultBuffer _buffer = new ConsoleBuffer(); // TODO instantiate based on args

final Logger _log = new Logger('dherkin');

/**
 * Runs specified gherkin files with provided flags. This is left for backwards compatibility.
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
    FeatureStatus featureStatus = await feature.execute(
        new DherkinState(stepRunners, null, {}, false), runTags: runTags, debug: debug);
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


class DherkinOpts {
  List<String> _features = [];
  List<Type> _stepdefs = [];
  String _scenario = null;
  Map<Type, InstanceMirror> _instances = {};
  bool _debug = false;
  String _tags = null;
  bool _failedOnMissingSteps = true;

  void features(String folderOrFile) {
    _features.add(folderOrFile);
  }

  void feature(String folderOrFile) {
    features(folderOrFile);
  }

  void steps(Type clazz) {
    step(clazz);
  }

  void step(Type clazz) {
    _stepdefs.add(clazz);
  }

  void instance(Object o) {
    _instances[o.runtimeType] = reflect(o);
  }

  void debug() {
    _debug = true;
  }

  void tags(String tags) {
    _tags = tags;
  }

  void failOnMissingSteps(bool f) {
    _failedOnMissingSteps = f;
  }

  String get scenario {
    return _scenario;
  }

  void _checkForEnvOverride() {
    String envOverride = Platform.environment['CUCUMBER'];
    
    if (envOverride != null) {
      if ("SCENARIO" == envOverride) {
        _features = [Platform.environment['CUCUMBER_FEATURE']];
        _scenario = Platform.environment['CUCUMBER_SCENARIO'];
      } else if ('FEATURE'  == envOverride) {
        _features = [Platform.environment['CUCUMBER_FEATURE']];
      } else {
        _features = [Platform.environment['CUCUMBER_FOLDER']];
      }
    }
  }


  /**
   * For each of the feature files or folders, determine which type it is, deref folders
   * into individual feature files.
   */
  List<String> _determineFeatureFiles() {
    List<String> files = [];

    _features.forEach((ff) {
      FileSystemEntityType type = FileSystemEntity.typeSync(ff);
      if (type == FileSystemEntityType.directory) {
        new Directory(ff).listSync(recursive: true, followLinks: true).forEach((f) {
          type = FileSystemEntity.typeSync(f.path);
          if (type == FileSystemEntityType.file && f.path.endsWith(".feature")) {
            _log.info("loaded feature ${f.path}");
            files.add(f.path);
          }
        });
      } else if (type == FileSystemEntityType.file) {
        if (ff.endsWith(".feature")) {
          _log.info("loaded feature ${ff}");
          files.add(ff);
        }
      } else {
        _log.severe("Cannot find ${ff}");
      }
    });

    if (files.length == 0) {
      _log.severe("No feature files found, offset is ${Directory.current.path}");
    }

    return files;
  }

  Future<RunStatus> run() async {
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });
    
    _checkForEnvOverride();

    if(_debug){
      Logger.root.level = Level.FINE;
    } else {
      Logger.root.level = Level.INFO;
    }

    List<String> runTags = _tags == null ? [] : _tags.split(",");

    var featureFiles = _determineFeatureFiles();
    RunStatus runStatus = new RunStatus();

    var stepRunners = await findStepRunners();
    await mergeClassStepRunners(_stepdefs, stepRunners);

    for (String filePath in featureFiles) {
      List<String> contents = await new File(filePath).readAsLines();
      Feature feature = await new GherkinParserTask(contents, filePath).execute();
      FeatureStatus featureStatus = await feature.execute(
          new DherkinState(stepRunners, _scenario, _instances, _failedOnMissingSteps), runTags: runTags, debug: _debug);
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

    return runStatus;
  }
}


