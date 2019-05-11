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

typedef HookFunc = Future<void> Function(OguretsScenarioSession scenarioSession, ScenarioStatus scenarioStatus);

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
        !(stepName.contains("{string}") || stepName.contains("{int}") || stepName.contains("{float}"))) return stepName;

    String nameIs = "^" +stepName.replaceAll("\{string\}", "\"([^\"]*)\"")
        .replaceAll("{int}", "([-+]?\\d+)")
        .replaceAll("{float}", "([-+]?[0-9]*\\.?[0-9]+)") + r"$";

    _log.info("transformed ${stepName} to ${nameIs}");

    return nameIs;
  }
  
  Future<OguretsState> findHooks(Type hookType, Map<String, List<HookFunc>> tagRunners, List<HookFunc> globalRunners) async {
    final hookTypeName = reflectClass(hookType).simpleName.toString();
    final hooksInOrder = Map<int, List<HookFunc>>();
    final tagHooksInOrder = Map<String, Map<int, List<HookFunc>>>();

    for (final Type type in steps) {
      final ClassMirror lib = reflectClass(type);
      
      for (final MethodMirror mm in lib.declarations.values
          .where((DeclarationMirror dm) =>
            dm is MethodMirror && dm.isRegularMethod)) {
          final filteredMetadata =
              mm.metadata.where((InstanceMirror im) => im.reflectee.runtimeType == hookType);
          final methodName = mm.simpleName;

          for (final InstanceMirror im in filteredMetadata) {
            var func = (OguretsScenarioSession scenarioSession, ScenarioStatus scenarioStatus) async {
              List<dynamic> params = [];

              // find the parameters, creating them if necessary
              for (ParameterMirror pm in mm.parameters) {
                if (!pm.isNamed ) {
                  if (pm.type.reflectedType == OguretsScenarioSession) {
                    params.add(scenarioSession);
                  } else {
                    params.add(scenarioSession.getInstance(pm.type.reflectedType).reflectee);
                  }
                }
              }

              InstanceMirror instance = scenarioSession.getInstance(type);

              var step = new Step(hookTypeName, hookTypeName,
                  scenarioStatus.scenario.location, scenarioStatus.scenario);

              var stepStatus = new StepStatus(scenarioStatus.fmt)..step = step;

              scenarioStatus.fmt.step(stepStatus);

              _log.fine(
                  "Executing ${methodName} hook with params: ${params}");

              try {
                var invoke = instance.invoke(methodName, params);

                if (invoke != null && invoke.reflectee is Future) {
                  await invoke.reflectee as Future;
                }
              } catch (e, s) {
                var failure = new StepFailure(e, s.toString());

                stepStatus.failure = failure;
                scenarioStatus.failedSteps.add(stepStatus);
                scenarioStatus.fmt.done(stepStatus);
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

    hooksInOrder.keys.toList()..sort()..forEach((o) => globalRunners.addAll(hooksInOrder[o]));
    tagHooksInOrder.keys.forEach((k) {
      tagHooksInOrder[k].keys.toList()..sort()..forEach((o) {
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
          stepRunners[new RegExp(_transformCucumberExpression(im.reflectee.verbiage))] =
              (params, Map namedParams, OguretsScenarioSession scenarioSession) async {
            _log.fine(
                "Executing ${mm.simpleName} with params: ${params} named params: ${namedParams}");

            Map<Symbol, dynamic> convertedNamedParams = _createParameters(namedParams, mm, params, _stringMirror);

            var invoke = await lib.invoke(mm.simpleName, params, convertedNamedParams);
            if (invoke != null && invoke.reflectee is Future) {
              await invoke.reflectee as Future;
            }
          };
        }
      }
    }

    return this;
  }


  Future<OguretsState> _findClassStyleStepRunners() async {
    for (final Type type in steps) {
      final ClassMirror lib = reflectClass(type);
      for (MethodMirror mm in lib.declarations.values
          .where((DeclarationMirror dm) => dm is MethodMirror && dm.isRegularMethod)) {
        var filteredMetadata =
        mm.metadata.where((InstanceMirror im) => im.reflectee is StepDef);
        for (InstanceMirror im in filteredMetadata) {
          _log.fine(im.reflectee.verbiage);
          stepRunners[new RegExp(_transformCucumberExpression(im.reflectee.verbiage))] =
              (List params, Map namedParams, OguretsScenarioSession scenarioSession) async {
            _log.fine(
                "Executing ${mm.simpleName} with params: ${params} named params: ${namedParams}");

            InstanceMirror instance = scenarioSession.getInstance(type);

            // these are the named parameters that were found in the scenario itself
            Map<Symbol, dynamic> convertedNamedParams = _createParameters(namedParams, mm, params, _stringMirror);

            var invoke = await instance.invoke(
                mm.simpleName, params, convertedNamedParams);

            if (invoke != null && invoke.reflectee is Future) {
              await invoke.reflectee as Future;
            }
          };
        }
      }
    }
    return this;
  }

  Map<Symbol, dynamic> _createParameters(Map namedParams, MethodMirror mm, List params, TypeMirror stringMirror) {
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
    for (int count = 0; count < mm.parameters.length; count ++) {
      ParameterMirror pm = mm.parameters[count];
      if (pm.type == stringMirror && !(params[count] is String)) {
        params[count] = params[count].toString();
      }
    }

    //  Remove possible optional params if the function doesn't want them
    for (Symbol possibleParam in _possibleParams) {
      mm.parameters.firstWhere(
              (ParameterMirror param) =>
          param.isNamed && param.simpleName == possibleParam,
          orElse: () {
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

  void runBeforeHooks(ScenarioStatus scenarioStatus, OguretsScenarioSession scenarioSession) async {
    await runHookList(scenarioStatus, scenarioSession, beforeRunners);

    await runScenarioTags(scenarioStatus, scenarioSession, namedBeforeTagRunners);
  }

  void runScenarioTags(ScenarioStatus scenarioStatus, OguretsScenarioSession scenarioSession, Map<String, List<HookFunc>> tagRunners) async {
    if (scenarioStatus.scenario.tags != null) {
      await Future.wait(scenarioStatus.scenario.tags.map((t) async {
        var funcList = tagRunners[t.substring(1)];
        if (funcList != null) {
          await runHookList(scenarioStatus, scenarioSession, funcList);
        }
      }).toList());
    }
  }

  void runHookList(ScenarioStatus scenarioStatus, OguretsScenarioSession scenarioSession, List<HookFunc> funcList) async {
    await Future.wait(funcList.map((f) => f(scenarioSession, scenarioStatus)).where((f) => f != null).toList());
  }

  void runAfterHooks(ScenarioStatus scenarioStatus, OguretsScenarioSession scenarioSession) async {
    await runHookList(scenarioStatus, scenarioSession, afterRunners);

    await runScenarioTags(scenarioStatus, scenarioSession, namedAfterTagRunners);
  }
}


