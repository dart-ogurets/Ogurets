part of ogurets;

/// The purpose of this file is to expose the internals of ogurets
/// without requiring dart:io, so that it can be used in the browser.

typedef HookFunc = Future<void> Function(
    OguretsScenarioSession scenarioSession, ScenarioStatus scenarioStatus);
typedef Future StepFunc(
    List params,
    Map namedParams,
    OguretsScenarioSession scenarioSession,
    ScenarioStatus scenarioStatus,
    StepStatus stepStatus);

class OguretsState {
  Map<RegExp, StepFunc> stepRunners = {};

  // all lists of hooks are sorted into order
  Map<String, List<HookFunc>> namedBeforeTagHooks = {};
  Map<String, List<HookFunc>> namedAfterTagHooks = {};

  // collections of before and after step runners. These get passed the step (thus an after step can trigger a screen shot for example)
  Map<String, List<HookFunc>> namedBeforeStepHooks = {};
  Map<String, List<HookFunc>> namedAfterStepHooks = {};
  List<Type> steps = [];

  /// these are not named, but are global and always run
  List<HookFunc> beforeScenarioHooks = [];
  List<HookFunc> afterScenarioHooks = [];

  /// these are not named, but are global and always run
  List<HookFunc> beforeStepGlobalHooks = [];
  List<HookFunc> afterStepGlobalHooks = [];
  String scenarioToRun;
  Map<Type, InstanceMirror> existingInstances = {};
  bool failOnMissingSteps = false;
  List<Formatter> formatters = [];
  Formatter fmt;
  final ResultBuffer resultBuffer;
  bool parallelRun = false;

  List<String> runTags;
  List<String> negativeTags;

  OguretsState(this.resultBuffer);

  void build() async {
    await _findMethodStyleStepRunners();
    await _findClassStyleStepRunners();

    if (steps != null && steps.isNotEmpty) {
      await findHooks(Before, namedBeforeTagHooks, beforeScenarioHooks);
      await findHooks(After, namedAfterTagHooks, afterScenarioHooks);
      await findHooks(BeforeStep, namedBeforeStepHooks, beforeStepGlobalHooks);
      await findHooks(AfterStep, namedAfterStepHooks, afterStepGlobalHooks);
    }

    if (formatters.isEmpty) {
      if (Platform.environment['CUCUMBER'] != null) {
        formatters.add(IntellijFormatter(resultBuffer));
      } else {
        formatters.add(BasicFormatter(resultBuffer));
      }
    }

    fmt = DelegatingFormatter(formatters);

    if (runTags == null) {
      runTags = [];
    }

    // grab the negs
    negativeTags = runTags
        .where((prefix) => prefix.startsWith("~"))
        .map((tag) => tag.substring(1))
        .toList();

    // take the negs out - can't do the previous way because negative tags will have stripped the "~"
    runTags.removeWhere((tag) => tag.startsWith("~"));
  }

  List<Symbol> _possibleParams = [
    Symbol("out"),
    Symbol("table"),
    Symbol("exampleRow")
  ];

  final TypeMirror _stringMirror = reflectType(String);

  String _transformCucumberExpression(String stepName) {
    if (stepName.startsWith("^") &&
        !(stepName.contains("{string}") ||
            stepName.contains("{int}") ||
            stepName.contains("{float}"))) return stepName;

    String nameIs = "^" +
        stepName
            .replaceAll("\{string\}", "\"([^\"]*)\"")
            .replaceAll("{int}", "([-+]?\\d+)")
            .replaceAll("{float}", "([-+]?[0-9]*\\.?[0-9]+)") +
        r"$";

    _log.info("Transformed step: ${stepName} to ${nameIs}");

    return nameIs;
  }

  String _decodeSymbol(Symbol s) {
    String name = s.toString().substring('Symbol("'.length);
    return name.substring(0, name.length - 2);
  }

  Future<OguretsState> findHooks(
      Type hookType,
      Map<String, List<HookFunc>> sortedTagRunners,
      List<HookFunc> sortedRunners) async {
    String hookTypeName = _decodeSymbol(reflectClass(hookType).simpleName);
    final hooksInOrder = Map<int, List<HookFunc>>();
    final tagHooksInOrder = Map<String, Map<int, List<HookFunc>>>();

    for (final Type type in steps) {
      final ClassMirror lib = reflectClass(type);

      for (final MethodMirror mm in lib.declarations.values.where(
          (DeclarationMirror dm) => dm is MethodMirror && dm.isRegularMethod)) {
        final filteredMetadata = mm.metadata
            .where((InstanceMirror im) => im.reflectee.runtimeType == hookType);
        final methodName = mm.simpleName;

        // this is really an IF as there can be only 1 hook annotation logically
        for (final InstanceMirror im in filteredMetadata) {
          var func = (OguretsScenarioSession scenarioSession,
              ScenarioStatus scenarioStatus) async {
            List<dynamic> params = [];

            // find the parameters, creating them if necessary
            for (ParameterMirror pm in mm.parameters) {
              if (!pm.isNamed) {
                if (pm.type.reflectedType == OguretsScenarioSession) {
                  params.add(scenarioSession);
                } else if (pm.type.reflectedType == ScenarioStatus) {
                  params.add(scenarioStatus);
                } else {
                  params.add(scenarioSession
                      .getInstance(pm.type.reflectedType)
                      .reflectee);
                }
              }
            }

            InstanceMirror instance = scenarioSession.getInstance(type);

            // this is really a hook that's getting created as a step
            var step = _Step(hookTypeName, hookTypeName,
                scenarioStatus.scenario.location, scenarioStatus.scenario,
                hook: true);

            var stepStatus = StepStatus(scenarioStatus.fmt)
              ..step = step
              ..decodedVerbiage = "${hookTypeName} - ${_decodeSymbol(methodName)}";

            scenarioStatus.fmt.step(stepStatus);

            _log.fine("Executing ${methodName} hook with params: ${params}");

            try {
              var invoke = instance.invoke(methodName, params);

              if (invoke != null && invoke.reflectee is Future) {
                await Future.sync(() => invoke.reflectee as Future);
              }
            } catch (e, s) {
              var failure = StepFailure(e, s.toString());

              stepStatus.failure = failure;
              scenarioStatus.failedSteps.add(stepStatus);
            } finally {
              stepStatus.sw.stop();
              scenarioStatus.fmt.done(stepStatus);
            }
          };

          final order = im.reflectee.order ?? 0;

          if (im.reflectee.tag != null) {
            _log.fine("Tag ${im.reflectee.tag} Hook -> ${mm.simpleName}");
            if (tagHooksInOrder[im.reflectee.tag] == null) {
              tagHooksInOrder[im.reflectee.tag] = Map<int, List<HookFunc>>();
            }
            if (tagHooksInOrder[im.reflectee.tag][order] == null) {
              tagHooksInOrder[im.reflectee.tag][order] = List<HookFunc>();
            }
            tagHooksInOrder[im.reflectee.tag][order].add(func);
          } else {
            if (hooksInOrder[order] == null) {
              hooksInOrder[order] = List<HookFunc>();
            }
            hooksInOrder[order].add(func);
          }
        }
      }
    }

    hooksInOrder.keys.toList()
      ..sort()
      ..forEach((o) => sortedRunners.addAll(hooksInOrder[o]));
    tagHooksInOrder.keys.forEach((k) {
      tagHooksInOrder[k].keys.toList()
        ..sort()
        ..forEach((o) {
          if (sortedTagRunners[k] == null) {
            sortedTagRunners[k] = List<HookFunc>();
          }

          sortedTagRunners[k].addAll(tagHooksInOrder[k][o]);
        });
    });

    return this;
  }

  ///  Scans the entirety of the vm for step definitions executables
  ///  This only picks up method level steps, not those in classes.
  Future<OguretsState> _findMethodStyleStepRunners() async {
    for (LibraryMirror lib in currentMirrorSystem().libraries.values) {
      for (MethodMirror mm
          in lib.declarations.values.whereType<MethodMirror>()) {
        var filteredMetadata =
            mm.metadata.where((InstanceMirror im) => im.reflectee is StepDef);
        for (InstanceMirror im in filteredMetadata) {
          _log.fine("Found step runner: ${im.reflectee.verbiage}");
          stepRunners[
                  RegExp(_transformCucumberExpression(im.reflectee.verbiage))] =
              (params, Map namedParams, OguretsScenarioSession scenarioSession,
                  ScenarioStatus scenarioStatus, StepStatus stepStatus) async {
            _log.fine(
                "Executing ${mm.simpleName} with params: ${params} named params: ${namedParams}");

            return executeStep(scenarioStatus, scenarioSession, namedParams, mm,
                params, lib, stepStatus);
          };
        }
      }
    }

    return this;
  }

  Future<OguretsState> _findClassStyleStepRunners() async {
    for (final Type type in steps) {
      final ClassMirror lib = reflectClass(type);
      for (MethodMirror mm in lib.declarations.values.where(
          (DeclarationMirror dm) => dm is MethodMirror && dm.isRegularMethod)) {
        var filteredMetadata =
            mm.metadata.where((InstanceMirror im) => im.reflectee is StepDef);
        for (InstanceMirror im in filteredMetadata) {
          _log.fine("Found class runner: ${im.reflectee.verbiage}");
          stepRunners[
                  RegExp(_transformCucumberExpression(im.reflectee.verbiage))] =
              (List params,
                  Map namedParams,
                  OguretsScenarioSession scenarioSession,
                  ScenarioStatus scenarioStatus,
                  StepStatus stepStatus) async {
            _log.fine(
                "Executing ${mm.simpleName} with params: ${params} named params: ${namedParams}");

            InstanceMirror instance = scenarioSession.getInstance(type);

            await executeStep(scenarioStatus, scenarioSession, namedParams, mm,
                params, instance, stepStatus);
          };
        }
      }
    }
    return this;
  }

  Future executeStep(
      ScenarioStatus scenarioStatus,
      OguretsScenarioSession scenarioSession,
      Map namedParams,
      MethodMirror mm,
      List params,
      ObjectMirror instance,
      StepStatus stepStatus) async {
    await runHookList(scenarioStatus, scenarioSession, beforeStepGlobalHooks);
    await runScenarioTags(
        scenarioStatus, scenarioSession, namedBeforeStepHooks);

    // these are the named parameters that were found in the scenario itself
    Map<Symbol, dynamic> convertedNamedParams =
        _createParameters(namedParams, mm, params, _stringMirror);

    try {
      await invokeStep(instance, mm, params, convertedNamedParams);
    } catch (e, s) {
      // move this here because the afterStep needs to know it failed.
      var failure = StepFailure(e, s.toString());

      stepStatus.failure = failure;
      scenarioStatus.failedSteps.add(stepStatus);

      rethrow;
    } finally {
      // try and ensure that the after step hooks run
      await runScenarioTags(
          scenarioStatus, scenarioSession, namedAfterStepHooks);
      await runHookList(scenarioStatus, scenarioSession, afterStepGlobalHooks);
    }
  }

  Future invokeStep(ObjectMirror instance, MethodMirror mm, List params,
      Map<Symbol, dynamic> convertedNamedParams) async {
    return await Future.sync(() {
      var invoke = instance.invoke(mm.simpleName, params, convertedNamedParams);

      if (invoke != null && invoke.reflectee is Future) {
        return invoke.reflectee as Future;
      }

      return invoke;
    });
  }

  Map<Symbol, dynamic> _createParameters(
      Map namedParams, MethodMirror mm, List params, TypeMirror stringMirror) {
    var convertedKeys = namedParams.keys.map((key) => Symbol(key));
    Map<Symbol, dynamic> convertedNamedParams =
        Map.fromIterables(convertedKeys, namedParams.values);

    // add to the end the missing params, however i think this can put
    // TODO: them in the wrong order?
    for (ParameterMirror pm in mm.parameters) {
      if (!pm.isNamed && convertedKeys.contains(pm.simpleName)) {
        var convertedNamedParam = convertedNamedParams[pm.simpleName];

        params.add(convertedNamedParam);
      }
    }

    // force them to strings if the parameters want them as such
    for (int count = 0; count < mm.parameters.length; count++) {
      ParameterMirror pm = mm.parameters[count];
      if (pm.type == stringMirror && !(params[count] is String)) {
        params[count] = params[count].toString();
      }
    }

    //  Remove possible optional params if the function doesn't want them
    for (Symbol possibleParam in _possibleParams) {
      mm.parameters.firstWhere(
          (ParameterMirror param) =>
              param.isNamed && param.simpleName == possibleParam, orElse: () {
        convertedNamedParams.remove(possibleParam);
        return null;
      });
    }
    return convertedNamedParams;
  }

  /// Do any of the [runTags] match one of [expectedTags]?
  /// If [runTags] is empty, anything matches.
  /// If there are [runTags] but no [expectedTags], don't match.
  bool tagsMatch(List<String> expectedTags) {
    return runTags.isEmpty
        ? true
        : runTags.any((element) => expectedTags.contains(element));
  }

  /// Do any of the [negativeTags] match one of [expectedTags] or @ignore?
  /// If [expectedTags] is empty, nothing matches.
  /// If there are no [negativeTags], return false as well
  bool negativeTagsMatch(List<String> expectedTags) {
    return negativeTags.isEmpty
        ? false
        : negativeTags.any((element) =>
            (expectedTags.contains(element) || element == "@ignore"));
  }

  void runBeforeHooks(ScenarioStatus scenarioStatus,
      OguretsScenarioSession scenarioSession) async {
    await runHookList(scenarioStatus, scenarioSession, beforeScenarioHooks);

    await runScenarioTags(scenarioStatus, scenarioSession, namedBeforeTagHooks);
  }

  void runScenarioTags(
      ScenarioStatus scenarioStatus,
      OguretsScenarioSession scenarioSession,
      Map<String, List<HookFunc>> tagRunners) async {
    if (scenarioStatus.scenario.tags != null) {
      await Future.wait(scenarioStatus.scenario.tags.map((t) async {
        var funcList = tagRunners[t.substring(1)];
        if (funcList != null) {
          await runHookList(scenarioStatus, scenarioSession, funcList);
        }
      }).toList());
    }
  }

  void runHookList(ScenarioStatus scenarioStatus,
      OguretsScenarioSession scenarioSession, List<HookFunc> funcList) async {
    for (var f in funcList) {
      await f(scenarioSession, scenarioStatus);
    }
  }

  void runAfterHooks(ScenarioStatus scenarioStatus,
      OguretsScenarioSession scenarioSession) async {
    await runHookList(scenarioStatus, scenarioSession, afterScenarioHooks);

    await runScenarioTags(scenarioStatus, scenarioSession, namedAfterTagHooks);
  }

  Future executeRunHooks(Type hookType) async {
    Map<int, List<Function>> runHooks = {};
    for (final Type type in existingInstances.keys) {
      final ClassMirror lib = reflectClass(type);
      for (MethodMirror mm in lib.declarations.values.where(
          (DeclarationMirror dm) => dm is MethodMirror && dm.isRegularMethod)) {
        var filteredMetadata = mm.metadata
            .where((InstanceMirror im) => im.reflectee.runtimeType == hookType);

        // essentially an IF on the meta-data,  this filters if this method
        for (InstanceMirror im in filteredMetadata) {
          var hook = () async {
            var result = existingInstances[type].invoke(mm.simpleName, []);
            if (result != null && result.reflectee is Future) {
              await Future.sync(() => result.reflectee as Future);
            }
          };
          final order = im.reflectee.order ?? 0;
          List<Function> functions = runHooks[order];
          if (functions == null) {
            functions = <Function>[];
            runHooks[order] = functions;
          }
          functions.add(hook);
        }
      }
    }

    var ordered = List<int>()
      ..addAll(runHooks.keys)
      ..sort();

    for (int order in ordered) {
      for (Function f in runHooks[order]) {
        await f();
      }
    }
  }
}
