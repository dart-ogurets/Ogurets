library ogurets_core3;

import "dart:async";
import 'dart:io';
import "dart:mirrors";
import "dart:collection";

import "package:logging/logging.dart";
import "package:ansicolor/ansicolor.dart";
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

part 'src/task.dart';

part 'src/model/scenario_session.dart';

part "src/gherkin_parser.dart";

part "src/status/status.dart";

part 'src/model/anotations.dart';

part 'src/model/background.dart';

part 'src/model/feature.dart';

part 'src/model/runtime.dart';

part 'src/model/scenario.dart';

part 'src/model/step.dart';

part 'src/model/table.dart';

part 'src/output/console_buffer.dart';

part 'src/output/output.dart';

part 'src/output/formatter.dart';

/// The purpose of this file is to expose the internals of ogurets
/// without requiring dart:io, so that it can be used in the browser.

final Logger _log = new Logger('ogurets');

typedef HookFunc = Future<void> Function(
    OguretsScenarioSession scenarioSession, ScenarioStatus scenarioStatus);

class OguretsState {
  Map<RegExp, Function> stepRunners = {};
  Map<String, List<HookFunc>> namedBeforeTagRunners = {};
  Map<String, List<HookFunc>> namedAfterTagRunners = {};
  List<Type> steps = [];
  List<HookFunc> beforeRunners = [];
  List<HookFunc> afterRunners = [];
  String scenarioToRun;
  Map<Type, InstanceMirror> existingInstances = {};
  bool failOnMissingSteps = false;
  List<Formatter> formatters = [];
  Formatter fmt;
  final ResultBuffer resultBuffer;

  OguretsState(this.resultBuffer);

  void build() async {
    await this._findMethodStyleStepRunners();

    if (steps != null && steps.length > 0) {
      await this._findClassStyleStepRunners();
      await findHooks(Before, namedBeforeTagRunners, beforeRunners);
      await findHooks(After, namedAfterTagRunners, afterRunners);
    }

    if (formatters.length == 0) {
      if (Platform.environment['CUCUMBER'] != null) {
        print("using IDEA");
        formatters.add(new IntellijFormatter(resultBuffer));
      } else {
        formatters.add(new BasicFormatter(resultBuffer));
      }
    }

    fmt = new DelegatingFormatter(formatters);
  }

  List<Symbol> _possibleParams = [
    new Symbol("out"),
    new Symbol("table"),
    new Symbol("exampleRow")
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

    _log.info("transformed ${stepName} to ${nameIs}");

    return nameIs;
  }

  String _decodeSymbol(Symbol s) {
    String name = s.toString().substring('Symbol("'.length);
    return name.substring(0, name.length - 2);
  }

  Future<OguretsState> findHooks(
      Type hookType,
      Map<String, List<HookFunc>> tagRunners,
      List<HookFunc> globalRunners) async {
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

        // this is really an IF as thehre can be only 1 hook annotation logically
        for (final InstanceMirror im in filteredMetadata) {
          var func = (OguretsScenarioSession scenarioSession,
              ScenarioStatus scenarioStatus) async {
            List<dynamic> params = [];

            // find the parameters, creating them if necessary
            for (ParameterMirror pm in mm.parameters) {
              if (!pm.isNamed) {
                if (pm.type.reflectedType == OguretsScenarioSession) {
                  params.add(scenarioSession);
                } else {
                  params.add(scenarioSession
                      .getInstance(pm.type.reflectedType)
                      .reflectee);
                }
              }
            }

            InstanceMirror instance = scenarioSession.getInstance(type);

            var step = new Step(hookTypeName, hookTypeName,
                scenarioStatus.scenario.location, scenarioStatus.scenario);

            var stepStatus = new StepStatus(scenarioStatus.fmt)..step = step;
            stepStatus.decodedVerbiage =
                "${hookTypeName} - ${_decodeSymbol(methodName)}";

            scenarioStatus.fmt.step(stepStatus);

            _log.fine("Executing ${methodName} hook with params: ${params}");

            try {
              if (!scenarioStatus.failed) {
                var invoke = instance.invoke(methodName, params);

                if (invoke != null && invoke.reflectee is Future) {
                  await Future.sync(() => invoke.reflectee as Future);
                }
              } else {
                stepStatus.skipped = true;
              }
            } catch (e, s) {
              var failure = new StepFailure(e, s.toString());

              stepStatus.failure = failure;
              scenarioStatus.failedSteps.add(stepStatus);
            } finally {
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
      ..forEach((o) => globalRunners.addAll(hooksInOrder[o]));
    tagHooksInOrder.keys.forEach((k) {
      tagHooksInOrder[k].keys.toList()
        ..sort()
        ..forEach((o) {
          if (tagRunners[k] == null) {
            tagRunners[k] = List<HookFunc>();
          }

          tagRunners[k].addAll(tagHooksInOrder[k][o]);
        });
    });

    return this;
  }

  ///  Scans the entirety of the vm for step definitions executables
  ///  This only picks up method level steps, not those in classes.
  Future<OguretsState> _findMethodStyleStepRunners() async {
    for (LibraryMirror lib in currentMirrorSystem().libraries.values) {
      for (MethodMirror mm in lib.declarations.values
          .where((DeclarationMirror dm) => dm is MethodMirror)) {
        var filteredMetadata =
            mm.metadata.where((InstanceMirror im) => im.reflectee is StepDef);
        for (InstanceMirror im in filteredMetadata) {
          _log.fine(im.reflectee.verbiage);
          stepRunners[new RegExp(
                  _transformCucumberExpression(im.reflectee.verbiage))] =
              (params, Map namedParams,
                  OguretsScenarioSession scenarioSession) async {
            _log.fine(
                "Executing ${mm.simpleName} with params: ${params} named params: ${namedParams}");

            Map<Symbol, dynamic> convertedNamedParams =
                _createParameters(namedParams, mm, params, _stringMirror);

            await Future.sync(() {
              var invoke =
                  lib.invoke(mm.simpleName, params, convertedNamedParams);
              if (invoke != null && invoke.reflectee is Future) {
                return invoke.reflectee as Future;
              }
            });
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
          _log.fine(im.reflectee.verbiage);
          stepRunners[new RegExp(
                  _transformCucumberExpression(im.reflectee.verbiage))] =
              (List params, Map namedParams,
                  OguretsScenarioSession scenarioSession) async {
            _log.fine(
                "Executing ${mm.simpleName} with params: ${params} named params: ${namedParams}");

            InstanceMirror instance = scenarioSession.getInstance(type);

            // these are the named parameters that were found in the scenario itself
            Map<Symbol, dynamic> convertedNamedParams =
                _createParameters(namedParams, mm, params, _stringMirror);

            await invokeStep(instance, mm, params, convertedNamedParams);
          };
        }
      }
    }
    return this;
  }

  Future invokeStep(InstanceMirror instance, MethodMirror mm, List params,
      Map<Symbol, dynamic> convertedNamedParams) async {
    await Future.sync(() {
      var invoke = instance.invoke(mm.simpleName, params, convertedNamedParams);

      if (invoke != null && invoke.reflectee is Future) {
        return invoke.reflectee as Future;
      }
    });
  }

  Map<Symbol, dynamic> _createParameters(
      Map namedParams, MethodMirror mm, List params, TypeMirror stringMirror) {
    var convertedKeys = namedParams.keys.map((key) => new Symbol(key));
    Map<Symbol, dynamic> convertedNamedParams =
        new Map.fromIterables(convertedKeys, namedParams.values);

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

  /// Do any of the [tags] match one of [expectedTags] ?
  /// If [expectedTags] is empty, anything matches.
  bool tagsMatch(List<String> tags, List<String> expectedTags) {
    return expectedTags.isEmpty ||
        tags.any((element) => expectedTags.contains(element));
  }

  void runBeforeHooks(ScenarioStatus scenarioStatus,
      OguretsScenarioSession scenarioSession) async {
    await runHookList(scenarioStatus, scenarioSession, beforeRunners);

    await runScenarioTags(
        scenarioStatus, scenarioSession, namedBeforeTagRunners);
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
    await runHookList(scenarioStatus, scenarioSession, afterRunners);

    await runScenarioTags(
        scenarioStatus, scenarioSession, namedAfterTagRunners);
  }

  Future executeRunHooks(Type hookType) async {
    Map<int, List<Function>> runHooks = {};
    for (final Type type in existingInstances.keys) {
      final ClassMirror lib = reflectClass(type);
      for (MethodMirror mm in lib.declarations.values.where(
              (DeclarationMirror dm) => dm is MethodMirror && dm.isRegularMethod)) {

        var filteredMetadata =
          mm.metadata.where((InstanceMirror im) => im.reflectee.runtimeType == hookType);

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

    var ordered = new List<int>()..addAll(runHooks.keys)..sort();

    for(int order in ordered) {
      for(Function f in runHooks[order]) {
        await f();
      }
    }
  }
}
