library ogurets;

import "dart:io";

import 'package:args/args.dart';
import "package:logging/logging.dart";
import "dart:mirrors";

import 'ogurets_core.dart';
import 'ogurets_core.dart';
export 'ogurets_core.dart';

final Logger _log = Logger('ogurets');

/// Runs specified gherkin files with provided flags. This is left for backwards compatibility.
/// [args] may be a list of filepaths.
run(args) async {
  var options = _parseArguments(args);

  // Use this to run with argument in IDE. Useful for debug.
  if (options.arguments == null || options.arguments.isEmpty) {
    var hardcodedArg = ['example/gherkin/test_feature.feature'];
    options = _parseArguments(hardcodedArg);
  }

  var debug = options["debug"];
  if (debug) {
    Logger.root.level = Level.FINE;
  } else {
    Logger.root.level = Level.INFO;
  }

  List<String> runTags = [];
  if (options["tags"] != null) {
    runTags = options["tags"].split(",");
  }

  var featureFiles = options.rest;
  OguretsState state = OguretsState(ConsoleBuffer());
  state.runTags = runTags;
  await state.build();

  RunStatus runStatus = RunStatus(state.fmt);

  for (String filePath in featureFiles) {
    List<String> contents = await File(filePath).readAsLines();
    Feature feature = await GherkinParserTask(contents, filePath).execute();
    FeatureStatus featureStatus = await feature.execute(state, debug: debug);
    if (featureStatus.failed) {
      runStatus.failedFeatures.add(featureStatus);
    } else {
      runStatus.passedFeatures.add(featureStatus);
    }
    state.fmt.done(featureStatus);
  }

  state.fmt.eof(runStatus);
}

/// Parses command line arguments.

ArgResults _parseArguments(args) {
  var argParser = ArgParser();
  argParser.addFlag('debug', defaultsTo: false);
  argParser.addOption("tags");
  return argParser.parse(args);
}

class OguretsOpts {
  List<String> _features = [];
  List<Type> _stepdefs = [];
  String _scenario;
  Map<Type, InstanceMirror> _instances = {};
  List<Object> _instanceObjects = [];
  List<Formatter> _formatters = <Formatter>[];
  bool _debug = false;
  String _tags;
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

  void hooks(Type clazz) {
    _stepdefs.add(clazz);
  }

  void instance(Object o) {
    _instances[o.runtimeType] = reflect(o);
    _instanceObjects.add(o);
  }

  void formatters(List<Formatter> fmts){
    _formatters.addAll(fmts);
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
      } else if ('FEATURE' == envOverride) {
        _features = [Platform.environment['CUCUMBER_FEATURE']];
      } else {
        _features = [Platform.environment['CUCUMBER_FOLDER']];
      }
    }
  }

  /// For each of the feature files or folders, determine which type it is, deref folders
  /// into individual feature files.
  List<String> _determineFeatureFiles() {
    List<String> files = [];

    _features.forEach((ff) {
      FileSystemEntityType type = FileSystemEntity.typeSync(ff);
      if (type == FileSystemEntityType.directory) {
        Directory(ff)
            .listSync(recursive: true, followLinks: true)
            .forEach((f) {
          type = FileSystemEntity.typeSync(f.path);
          if (type == FileSystemEntityType.file &&
              f.path.endsWith(".feature")) {
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

    if (files.isEmpty) {
      _log.severe(
          "No feature files found, offset is ${Directory.current.path}");
    }

    return files;
  }

  Future<RunStatus> run({List<String> args}) async {
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });

    _checkForEnvOverride();
    _ensureAssertsActive();

    if (_debug) {
      Logger.root.level = Level.FINE;
    } else {
      Logger.root.level = Level.INFO;
    }

    List<String> runTags = _tags == null ? [] : _tags.split(",").map((t) => t.trim()).toList();

    // command line overrides
    if (args != null) {
      var options = _parseArguments(args);
      if (options["tags"] != null) {
        runTags = options["tags"].split(",").map((t) => t.trim()).toList();
      }

      if (options["debug"]) {
        Logger.root.level = Level.FINE;
      }
    }

    if (Platform.environment['OGURETS_TAGS'] != null) {
      runTags = Platform.environment['OGURETS_TAGS'].split(",").map((t) => t.trim()).toList();
    }

    _log.info("Tags used are $runTags");

    var featureFiles = _determineFeatureFiles();

    OguretsState state = OguretsState(ConsoleBuffer());
    state.steps = this._stepdefs;
    state.failOnMissingSteps = this._failedOnMissingSteps;
    state.scenarioToRun = this._scenario;
    state.existingInstances = _instances;
    state.formatters = _formatters;
    state.runTags = runTags;

    await state.build();
    await state.executeRunHooks(BeforeRun);

    try {
      RunStatus runStatus = RunStatus(state.fmt);

      for (String filePath in featureFiles) {
        List<String> contents = await File(filePath).readAsLines();
        Feature feature =
            await GherkinParserTask(contents, filePath).execute();
        FeatureStatus featureStatus =
            await feature.execute(state, debug: _debug);
        if (featureStatus.failed) {
          runStatus.failedFeatures.add(featureStatus);
        } else {
          runStatus.passedFeatures.add(featureStatus);
        }
      }

      state.fmt.eof(runStatus);

      state.resultBuffer.flush();

      return runStatus;
    } finally {
      await state.executeRunHooks(AfterRun);
    }
  }

  void _ensureAssertsActive() {
    try {
      assert(true == false);
    } catch (e) {
      // all good
      return;
    }

    throw Exception(
        "Please enable asserts with --enable-asserts - VM options are: ${Platform.environment['DART_VM_OPTIONS']}");
  }
}
