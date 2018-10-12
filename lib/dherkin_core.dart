library dherkin_core;

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

List<Symbol> _possibleParams = [
  new Symbol("out"),
  new Symbol("table"),
  new Symbol("exampleRow")
];

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
        stepRunners[new RegExp(im.reflectee.verbiage)] =
            (params, Map namedParams) async {
          _log.fine(
              "Executing ${mm.simpleName} with params: ${params} named params: ${namedParams}");

          var convertedKeys = namedParams.keys.map((key) => new Symbol(key));
          Map<Symbol, dynamic> convertedNamedParams =
              new Map.fromIterables(convertedKeys, namedParams.values);

          //  Remove possible optional params if the function doesn't want them
          for (Symbol possibleParam in _possibleParams) {
            mm.parameters.firstWhere(
                (ParameterMirror param) =>
                    param.isNamed && param.simpleName == possibleParam,
                orElse: () => convertedNamedParams.remove(possibleParam));
          }
          Completer completer = new Completer();
          params.insert(0, completer);
          var scenarioStep =
              () => lib.invoke(mm.simpleName, params, convertedNamedParams);
          scenarioStep();
          await completer.future;
        };
      }
    }
  }
  return stepRunners;
}

/// Do any of the [tags] match one of [expectedTags] ?
/// If [expectedTags] is empty, anything matches.
bool _tagsMatch(tags, expectedTags) {
  return expectedTags.isEmpty ||
      tags.any((element) => expectedTags.contains(element));
}
