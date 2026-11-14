part of '../ogurets.dart';

/// Runs specified gherkin files with provided flags. This is left for backwards compatibility.
/// [args] may be a list of filepaths.
@Deprecated("Left for backwards compatibility...")
Future<void> run(List<String> args) async {
  var options = _parseArguments(args);

  // Use this to run with argument in IDE. Useful for debug.
  if (args.isEmpty) {
    options = _parseArguments(['example/gherkin/test_feature.feature']);
  }

  final debug = options.debug;
  if (debug) {
    Logger.root.level = Level.FINE;
  } else {
    Logger.root.level = Level.INFO;
  }

  List<String>? runTags = options.tags;

  final featureFiles = options.rest;
  final log = Logger('ogurets');
  OguretsState state = OguretsState(log, ConsoleBuffer(log));
  state.runTags = runTags;
  await state.build();

  RunStatus runStatus = RunStatus(state.fmt);

  for (String filePath in featureFiles) {
    List<String> contents = await File(filePath).readAsLines();
    final feature = await GherkinParserTask(log, contents, filePath).execute();
    if (feature == null) {
      continue; // no Feature in this file
    }
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

/// The command line options ogurets understands.
class _OguretsArgs {
  /// Tags from every `--tags` option, in order.
  final List<String> tags = [];

  /// `--debug`: log at FINE level.
  bool debug = false;

  /// `--replace-tags`: use only the command line / environment tags, instead of
  /// adding them to the tags configured with [OguretsOpts.tags].
  bool replaceTags = false;

  /// Arguments that are not options (feature files for the deprecated top-level `run`).
  final List<String> rest = [];
}

/// Parses the options ogurets understands out of [args]:
/// `--tags <tags>` / `--tags=<tags>` (repeatable), `--replace-tags` and `--debug`.
///
/// Anything else is ignored rather than rejected, so `main`'s arguments can be
/// shared with other code.
_OguretsArgs _parseArguments(List<String> args) {
  final options = _OguretsArgs();

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--') {
      options.rest.addAll(args.skip(i + 1));
      break;
    } else if (arg == '--debug') {
      options.debug = true;
    } else if (arg == '--replace-tags') {
      options.replaceTags = true;
    } else if (arg == '--tags') {
      if (i + 1 < args.length) {
        options.tags.addAll(_splitTags(args[++i]));
      }
    } else if (arg.startsWith('--tags=')) {
      options.tags.addAll(_splitTags(arg.substring('--tags='.length)));
    } else if (!arg.startsWith('-')) {
      options.rest.add(arg);
    }
  }

  return options;
}

/// Splits a comma separated list of tags, dropping empty entries.
List<String> _splitTags(String? tags) => [
  for (final tag in (tags ?? '').split(','))
    if (tag.trim().isNotEmpty) tag.trim(),
];

class OguretsOpts {
  List<String?> _features = [];
  final List<String> _stepdefLocs = [];
  final List<Type> _stepdefs = [];
  String? _scenario;
  final Map<Type, InstanceMirror> _instances = {};
  final List<Object> _instanceObjects = [];
  final Set<Formatter> _formatters = <Formatter>{};
  Set<Filter> filters = {};
  bool _debug = false;
  String? _tags;
  bool _failedOnMissingSteps = true;
  bool _useAsserts = true;
  bool _parallel = false;
  final Logger _log = Logger('ogurets');

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
      _log.warning(
        'Skipping abstract type ${lib.simpleName}, assuming a subclass will be present to pick up its step methods',
      );
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
      case LogLevel.all:
        _log.level = Level.ALL;
        break;
      case LogLevel.off:
        _log.level = Level.OFF;
        break;
      case LogLevel.finest:
        _log.level = Level.FINEST;
        break;
      case LogLevel.finer:
        _log.level = Level.FINER;
        break;
      case LogLevel.fine:
        _log.level = Level.FINE;
        break;
      case LogLevel.config:
        _log.level = Level.CONFIG;
        break;
      case LogLevel.info:
        _log.level = Level.INFO;
        break;
      case LogLevel.warning:
        _log.level = Level.WARNING;
        break;
      case LogLevel.severe:
        _log.level = Level.SEVERE;
        break;
      case LogLevel.shout:
        _log.level = Level.SHOUT;
        break;
    }
  }

  /// Shared [Object] instance for all tests
  void instance(Object o) {
    _instances[o.runtimeType] = reflect(o);
    _instanceObjects.add(o);
  }

  /// List of [Formatter] derived classes
  /// that can be used to provide custom output formats
  void formatters(Set<Formatter> fmts) {
    _formatters.addAll(fmts);
  }

  void filter(Filter filter) {
    filters.add(filter);
  }

  /// Enable fine output logging
  void debug() {
    _debug = true;
  }

  /// Tags in a comma-separated string
  /// @TagName would be a tag to limit
  /// ~@TagName would be a tag to exclude
  ///
  /// Tags given on the command line (`--tags`, when [run] is passed `args`)
  /// or in the `OGURETS_TAGS` environment variable are added to these, unless
  /// `--replace-tags` or `OGURETS_REPLACE_TAGS=true` is set, in which case
  /// only the command line / environment tags are used.
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
  Future<List<Type>> _determineStepDefs() async {
    List<File> files = [];

    for (var sl in _stepdefLocs) {
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
        _log.severe("Cannot find $sl");
      }
    }

    List<Type> classes = [];
    for (final f in files) {
      // load the found files into the current isolate
      var im = await currentMirrorSystem().isolate.loadUri(f.absolute.uri);

      // add any classes found to our return set
      for (var classMirror in im.declarations.values.whereType<ClassMirror>()) {
        _log.fine("Step class added: ${classMirror.reflectedType}");
        classes.add(classMirror.reflectedType);
      }
    }

    return classes;
  }

  /// For each of the feature files or folders, determine which type it is, deref folders
  /// into individual feature files.
  List<String?> _determineFeatureFiles() {
    List<String?> files = [];

    for (var ff in _features) {
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
          _log.info("Loaded feature: $ff");
          files.add(ff);
        }
      } else {
        _log.severe("Cannot find $ff");
      }
    }

    if (files.isEmpty) {
      _log.severe(
        "No feature files found, offset is ${Directory.current.path}",
      );
    }

    return files;
  }

  bool _isTrue(String? value) =>
      value != null && const {'true', '1', 'yes'}.contains(value.toLowerCase());

  /// Runs the configured features.
  ///
  /// Pass `main`'s [args] to let the command line add tags (`--tags "@a,~@b"`),
  /// replace the configured tags (`--replace-tags`) or turn on `--debug`.
  /// Other arguments are ignored.
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

    final options = _parseArguments(args ?? const []);
    if (options.debug) {
      Logger.root.level = Level.FINE;
    }

    // command line and environment tags are added to the configured ones,
    // unless asked to replace them
    final extraTags = [
      ...options.tags,
      ..._splitTags(Platform.environment['OGURETS_TAGS']),
    ];
    final replaceTags =
        options.replaceTags ||
        _isTrue(Platform.environment['OGURETS_REPLACE_TAGS']);

    List<String>? runTags = {
      if (!replaceTags) ..._splitTags(_tags),
      ...extraTags,
    }.toList();

    _log.info("Tags used are $runTags");

    var featureFiles = _determineFeatureFiles();
    var steps = await _determineStepDefs();
    _stepdefs.addAll(steps);

    OguretsState state = OguretsState(_log, ConsoleBuffer(_log));
    state.steps = _stepdefs;
    state.failOnMissingSteps = _failedOnMissingSteps;
    state.scenarioToRun = _scenario;
    state.existingInstances = _instances;
    state.formatters = _formatters;
    state.runTags = runTags;
    state.parallelRun = _parallel;
    state.formatFilters = filters;

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
    String filePath,
    RunStatus runStatus,
    OguretsState state,
  ) async {
    List<String> contents = await File(filePath).readAsLines();
    GherkinFeature? feature = await GherkinParserTask(
      _log,
      contents,
      filePath,
    ).execute();

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
      "Please enable asserts with --enable-asserts - arguments are ${Platform.executableArguments.toString()}",
    );
  }
}

/// Abstraction of log levels so packages don't need to add the "logger" depencency
enum LogLevel {
  all,
  off,
  finest,
  finer,
  fine,
  config,
  info,
  warning,
  severe,
  shout,
}
