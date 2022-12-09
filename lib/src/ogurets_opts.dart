part of ogurets;

/// Runs specified gherkin files with provided flags. This is left for backwards compatibility.
/// [args] may be a list of filepaths.
@Deprecated("Left for backwards compatibility...")
Future<void> run(args) async {
  var options = _parseArguments(args);

  // Use this to run with argument in IDE. Useful for debug.
  if (options.arguments.isEmpty) {
    var hardcodedArg = ['example/gherkin/test_feature.feature'];
    options = _parseArguments(hardcodedArg);
  }

  final debug = options["debug"];
  if (debug) {
    Logger.root.level = Level.FINE;
  } else {
    Logger.root.level = Level.INFO;
  }

  List<String>? runTags = [];
  if (options["tags"] != null) {
    runTags = options["tags"].split(",");
  }

  final featureFiles = options.rest;
  final _log = Logger('ogurets');
  OguretsState state = OguretsState(_log, ConsoleBuffer(_log));
  state.runTags = runTags;
  await state.build();

  RunStatus runStatus = RunStatus(state.fmt);

  for (String filePath in featureFiles) {
    List<String> contents = await File(filePath).readAsLines();
    _Feature feature = await (GherkinParserTask(_log, contents, filePath).execute()
        as FutureOr<_Feature>);
    FeatureStatus featureStatus = await feature.execute(state, debug: debug);
    if (featureStatus.failed) {
      runStatus.failedFeatures.add(featureStatus);
    } else if (featureStatus.skipped) {
      runStatus.skippedFeatures.add(featureStatus);
    } else {
      runStatus.passedFeatures.add(featureStatus);
    }
    state.fmt!.done(featureStatus);
  }

  state.fmt!.eof(runStatus);
}

/// Parses command line arguments.

ArgResults _parseArguments(args) {
  var argParser = ArgParser();
  argParser.addFlag('debug', defaultsTo: false);
  argParser.addOption("tags");
  return argParser.parse(args);
}

class OguretsOpts {
  List<String?> _features = [];
  List<String> _stepdefLocs = [];
  List<Type> _stepdefs = [];
  String? _scenario;
  Map<Type, InstanceMirror> _instances = {};
  List<Object> _instanceObjects = [];
  List<Formatter> _formatters = <Formatter>[];
  bool _debug = false;
  String? _tags;
  bool _failedOnMissingSteps = true;
  bool _useAsserts = true;
  bool _parallel = false;
  Logger _log = Logger('ogurets');

  /// Add a [List<String>] that are locations of folders
  /// that contain feature files (recursed), specific paths to feature files
  /// or a mix of the two
  void features(List<String> foldersOrFiles) {
    _features.addAll(foldersOrFiles);
  }

  void parallelize() {
    _parallel = true;
  }

  /// Add a location of a folder that contains feature files
  /// or a specific path to a feature file
  void feature(String folderOrFile) {
    _features.add(folderOrFile);
  }

  /// Add a location of a folder
  /// that contains step definition files.
  /// It will load all classes found as step def types (recursive)
  void steps(String folder) {
    _stepdefLocs.add(folder);
  }

  /// Add a [Type] with defined step definitions
  void step(Type clazz) {
    final ClassMirror lib = reflectClass(clazz);
    if (lib.isAbstract) {
      _log.warning('Skipping abstract type ${lib.simpleName}, assuming a subclass will be present to pick up its step methods');
    } else {
      _stepdefs.add(clazz);
    }
  }

  /// Add a [Type] with defined hook definitions
  void hooks(Type clazz) {
    _stepdefs.add(clazz);
  }

  /// Set the [LogLevel] used while running ogurets.
  void logLevel(LogLevel level) {
    hierarchicalLoggingEnabled = true;
    switch (level) {
      case LogLevel.ALL : _log.level = Level.ALL; break;
      case LogLevel.OFF : _log.level = Level.OFF; break;
      case LogLevel.FINEST : _log.level = Level.FINEST; break;
      case LogLevel.FINER : _log.level = Level.FINER; break;
      case LogLevel.FINE : _log.level = Level.FINE; break;
      case LogLevel.CONFIG : _log.level = Level.CONFIG; break;
      case LogLevel.INFO : _log.level = Level.INFO; break;
      case LogLevel.WARNING : _log.level = Level.WARNING; break;
      case LogLevel.SEVERE : _log.level = Level.SEVERE; break;
      case LogLevel.SHOUT : _log.level = Level.SHOUT; break;
    }
  }

  /// Shared [Object] instance for all tests
  void instance(Object o) {
    _instances[o.runtimeType] = reflect(o);
    _instanceObjects.add(o);
  }

  /// List of [Formatter] derived classes
  /// that can be used to provide custom output formats
  void formatters(List<Formatter> fmts) {
    _formatters.addAll(fmts);
  }

  /// Enable fine output logging
  void debug() {
    _debug = true;
  }

  /// Tags in a comma-separated string
  /// @TagName would be a tag to limit
  /// ~@TagName would be a tag to exclude
  void tags(String tags) {
    _tags = tags;
  }

  /// Specify whether or not to log scenarios with missing steps as failures
  void failOnMissingSteps(bool f) {
    _failedOnMissingSteps = f;
  }

  /// Name of a specific scenario to run
  void scenario(String s) {
    _scenario = s;
  }

  /// Specify whether or not to use asserts
  /// true by default, but flutter drive doesn't
  /// call dart with enable-asserts
  void useAsserts(bool u) {
    _useAsserts = u;
  }

  void _checkForEnvOverride() {
    String? envOverride = Platform.environment['CUCUMBER'];

    if (envOverride != null) {
      if ("SCENARIO" == envOverride) {
        _features = [Platform.environment['CUCUMBER_FEATURE']];
        _scenario = Platform.environment['CUCUMBER_SCENARIO'];
      } else if ('FEATURE' == envOverride) {
        _features = [Platform.environment['CUCUMBER_FEATURE']];
      } else if (Platform.environment['CUCUMBER_FOLDER'] != null) {
        _features = [Platform.environment['CUCUMBER_FOLDER']];
      }

      if (Platform.environment['CUCUMBER_PARALLEL'] != null) {
        _parallel = true;
      }
    }
  }

  /// For the list of step definition locations, find the types in the files and add them
  /// to the current isolate so that the runner can resolve the steps
  /// Does not handle steps outside of classes
  List<Type> _determineStepDefs() {
    List<File> files = [];

    _stepdefLocs.forEach((sl) {
      FileSystemEntityType type = FileSystemEntity.typeSync(sl);
      if (type == FileSystemEntityType.directory) {
        Directory(sl).listSync(recursive: true, followLinks: true).forEach((f) {
          type = FileSystemEntity.typeSync(f.path);
          if (type == FileSystemEntityType.file && f.path.endsWith(".dart")) {
            _log.fine("Loaded step file: ${f.path}");
            files.add(File(f.path));
          }
        });
      } else {
        _log.severe("Cannot find ${sl}");
      }
    });

    List<Type> classes = [];
    files.forEach((f) async {
      // load the found files into the current isolate
      var im = await currentMirrorSystem().isolate.loadUri(f.absolute.uri);

      // add any classes found to our return set
      for (var classMirror in im.declarations.values.whereType<ClassMirror>()) {
        _log.fine("Step class added: ${classMirror.reflectedType}");
        classes.add(classMirror.reflectedType);
      }
    });

    return classes;
  }

  /// For each of the feature files or folders, determine which type it is, deref folders
  /// into individual feature files.
  List<String?> _determineFeatureFiles() {
    List<String?> files = [];

    _features.forEach((ff) {
      FileSystemEntityType type = FileSystemEntity.typeSync(ff!);
      if (type == FileSystemEntityType.directory) {
        Directory(ff).listSync(recursive: true, followLinks: true).forEach((f) {
          type = FileSystemEntity.typeSync(f.path);
          if (type == FileSystemEntityType.file &&
              f.path.endsWith(".feature")) {
            _log.info("Loaded feature: ${f.path}");
            files.add(f.path);
          }
        });
      } else if (type == FileSystemEntityType.file) {
        if (ff.endsWith(".feature")) {
          _log.info("Loaded feature: ${ff}");
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

  Future<RunStatus> run({List<String>? args}) async {
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });

    _checkForEnvOverride();

    // flutter drive starts dart without enable-asserts to run tests, so we can't always check
    if (_useAsserts) {
      _ensureAssertsActive();
    }

    if (_debug) {
      Logger.root.level = Level.FINE;
    } else {
      Logger.root.level = Level.INFO;
    }

    List<String>? runTags =
        _tags == null ? [] : _tags!.split(",").map((t) => t.trim()).toList();

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
      runTags = Platform.environment['OGURETS_TAGS']!
          .split(",")
          .map((t) => t.trim())
          .toList();
    }

    _log.info("Tags used are $runTags");

    var featureFiles = _determineFeatureFiles();
    var steps = await _determineStepDefs();
    this._stepdefs.addAll(steps);

    OguretsState state = OguretsState(_log, ConsoleBuffer(_log));
    state.steps = this._stepdefs;
    state.failOnMissingSteps = this._failedOnMissingSteps;
    state.scenarioToRun = this._scenario;
    state.existingInstances = _instances;
    state.formatters = _formatters;
    state.runTags = runTags;
    state.parallelRun = _parallel;

    await state.build();
    await state.executeRunHooks(BeforeRun);

    try {
      RunStatus runStatus = RunStatus(state.fmt);

      List<Future> awaitingFeatures = [];
      for (String? filePath in featureFiles) {
        if (state.parallelRun) {
          awaitingFeatures.add(processFeatureFile(filePath!, runStatus, state));
        } else {
          await processFeatureFile(filePath!, runStatus, state);
        }
      }

      if (awaitingFeatures.isNotEmpty) {
        await Future.wait(awaitingFeatures); // wait for all features to finish
      }

      runStatus.sw.stop();
      state.fmt!.eof(runStatus);

      state.resultBuffer.flush();

      return runStatus;
    } finally {
      await state.executeRunHooks(AfterRun);
    }
  }

  Future processFeatureFile(
      String filePath, RunStatus runStatus, OguretsState state) async {
    List<String> contents = await File(filePath).readAsLines();
    _Feature? feature = await GherkinParserTask(_log, contents, filePath).execute();

    if (feature != null) {
//    _log.info("Parsing took ${runStatus.sw.elapsedMilliseconds} ms");
      FeatureStatus featureStatus = await feature.execute(state, debug: _debug);

      if (featureStatus.failed) {
        runStatus.failedFeatures.add(featureStatus);
      } else if (featureStatus.skipped) {
        runStatus.skippedFeatures.add(featureStatus);
      } else {
        runStatus.passedFeatures.add(featureStatus);
      }
    }
  }

  void _ensureAssertsActive() {
    try {
      assert(true == false);
    } catch (e) {
      // all good
      _log.info("Asserts are enabled");
      return;
    }

    throw Exception(
        "Please enable asserts with --enable-asserts - arguments are ${Platform.executableArguments.toString()}");
  }
}

/// Abstraction of log levels so packages don't need to add the "logger" depencency
enum LogLevel {
  ALL,
  OFF,
  FINEST,
  FINER,
  FINE,
  CONFIG,
  INFO,
  WARNING,
  SEVERE,
  SHOUT,
}
