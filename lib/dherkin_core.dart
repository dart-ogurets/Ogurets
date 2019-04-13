library dherkin_core3;

import "dart:async";
import "dart:mirrors";
import "dart:collection";

import "package:logging/logging.dart";
import "package:ansicolor/ansicolor.dart";

part 'src/task.dart';

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

/// The pupose of this file is to expose the internals of dherkin
/// without requiring dart:io, so that it can be used in the browser.

final Logger _log = new Logger('dherkin');

class DherkinState {
  Map<RegExp, Function> stepRunners;
  String scenarioToRun;
  Map<Type, InstanceMirror> existingInstances;
  bool failOnMissingSteps;

  DherkinState(this.stepRunners, this.scenarioToRun, this.existingInstances, this.failOnMissingSteps);
}

List<Symbol> _possibleParams = [
  new Symbol("out"),
  new Symbol("table"),
  new Symbol("exampleRow")
];

String _transformCucumberExpression(String stepName) {
  if (stepName.startsWith("^") &&
      !(stepName.contains("{string}") || stepName.contains("{int}") || stepName.contains("{float}"))) return stepName;

  String nameIs = "^" +stepName.replaceAll("\{string\}", "\"([^\"]*)\"")
      .replaceAll("{int}", "(\\d+)")
      .replaceAll("{float}", "([-+]?[0-9]*\\.?[0-9]+)") + r"$";

  _log.info("transformed ${stepName} to ${nameIs}");

  return nameIs;
}

///  Scans the entirety of the vm for step definitions executables
///  TODO : refactor to be less convoluted.
Future<Map<RegExp, Function>> findStepRunners() async {
  Map<RegExp, Function> stepRunners = new Map();
  for (LibraryMirror lib in currentMirrorSystem().libraries.values) {
    for (MethodMirror mm in lib.declarations.values
        .where((DeclarationMirror dm) => dm is MethodMirror)) {
      var filteredMetadata =
          mm.metadata.where((InstanceMirror im) => im.reflectee is StepDef);
      for (InstanceMirror im in filteredMetadata) {
        _log.fine(im.reflectee.verbiage);
        stepRunners[new RegExp(_transformCucumberExpression(im.reflectee.verbiage))] =
            (params, Map namedParams, Map<Type, Object> instances) async {
          _log.fine(
              "Executing ${mm.simpleName} with params: ${params} named params: ${namedParams}");

          var convertedKeys = namedParams.keys.map((key) => new Symbol(key));
          Map<Symbol, dynamic> convertedNamedParams =
              new Map.fromIterables(convertedKeys, namedParams.values);

          for (ParameterMirror pm in mm.parameters) {
            if (!pm.isNamed && convertedKeys.contains(pm.simpleName)) {
              params.add(convertedNamedParams[pm.simpleName]);
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
          
          var scenarioStep =
              () => lib.invoke(mm.simpleName, params, convertedNamedParams);
          await scenarioStep();
        };
      }
    }
  }
  return stepRunners;
}

List<DeclarationMirror> _constructors(ClassMirror mirror) {
  return List.from(
    mirror.declarations.values.where((declare) {
      return declare is MethodMirror && declare.isConstructor;
    }));
}

List<ParameterMirror> _params(var methodMirror) {
  if (methodMirror is MethodMirror) {
    return methodMirror.parameters;
  } else {
    return [];
  }
}

// recursively construct the object if necessary and stick each one into
// the instances map
InstanceMirror _newInstance(ClassMirror cm, Map<Type, InstanceMirror> instances) {
  InstanceMirror newInst;

  List<DeclarationMirror> c = _constructors(cm);
  if (c.length > 0) {
    DeclarationMirror constructor = c[0];
    List<ParameterMirror> params = _params(constructor);
    List<Object> positionalArgs = [];
    // find the positional arguments in the existing instances map, and if they aren't
    // there try and recursively create them. This will of course explode with a stack overflow
    // if we have a circular situation.
    params.forEach((p) {
      InstanceMirror inst = instances[p.type.reflectedType];
      if (inst == null) {
        inst = _newInstance(reflectClass(p.type.reflectedType), instances);
      }
      positionalArgs.add(inst.reflectee);
    });

    Symbol constName = constructor.simpleName == cm.simpleName ? const Symbol("") : constructor.simpleName;
    newInst = cm.newInstance(constName, positionalArgs);
    instances[cm.reflectedType] = newInst;

  } else {
    newInst = cm.newInstance(const Symbol(""), []);
    instances[cm.reflectedType] = newInst;
  }

  return newInst;
}

Future<Map<RegExp, Function>> mergeClassStepRunners(List<Type> types, Map<RegExp, Function> stepRunners) async {
  final TypeMirror stringMirror = reflectType(String);
  for (final Type type in types) {
    final ClassMirror lib = reflectClass(type);
    for (MethodMirror mm in lib.declarations.values
        .where((DeclarationMirror dm) => dm is MethodMirror && dm.isRegularMethod)) {
      var filteredMetadata =
      mm.metadata.where((InstanceMirror im) => im.reflectee is StepDef);
      for (InstanceMirror im in filteredMetadata) {
        _log.fine(im.reflectee.verbiage);
        stepRunners[new RegExp(_transformCucumberExpression(im.reflectee.verbiage))] =
            (List params, Map namedParams, Map<Type, InstanceMirror> instances) async {
          _log.fine(
              "Executing ${mm.simpleName} with params: ${params} named params: ${namedParams}");

          InstanceMirror instance = instances[type];
          if (instance == null) {
            instance = _newInstance(lib, instances);
          }

          // these are the named parameters that were found in the scenario itself
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

          var scenarioStep =
              () => instance.invoke(mm.simpleName, params, convertedNamedParams);
          await scenarioStep();
        };
      }
    }
  }
  return stepRunners;
}

/// Do any of the [tags] match one of [expectedTags] ?
/// If [expectedTags] is empty, anything matches.
bool _tagsMatch(List<String> tags, List<String> expectedTags) {
  return expectedTags.isEmpty ||
      tags.any((element) => expectedTags.contains(element));
}
