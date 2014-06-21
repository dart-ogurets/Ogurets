library dherkin_core;

import "dart:async";
import "dart:mirrors";

import "package:log4dart/log4dart.dart";
import "package:worker/worker.dart";
import "package:ansicolor/ansicolor.dart";

part 'src/task.dart';
part "src/gherkin_model.dart";
part "src/gherkin_parser.dart";
part "src/outputter.dart";


/// The pupose of this file is to expose the internals of dherkin
/// without requiring dart:io, so that it can be used in the browser.

final _STEPDEF_NOTFOUND = new RegExp("###");

Logger _log = LoggerFactory.getLogger("dherkin");

///  Scans the entirety of the vm for step definitions executables
///  TODO : refactor to be less convoluted.
Future<Map<RegExp,Function>> findStepRunners() {
  Completer comp = new Completer();
  Map<RegExp,Function> stepRunners = new Map();
  stepRunners[_STEPDEF_NOTFOUND] = (ctx, params, named) { throw new StepDefUndefined(); };
  Future.forEach(currentMirrorSystem().libraries.values, (LibraryMirror lib) {
    return new Future.sync(() {
      Future.forEach(lib.declarations.values.where((DeclarationMirror dm) => dm is MethodMirror), (MethodMirror mm) {
        return new Future.sync(() {
          var filteredMetadata = mm.metadata.where((InstanceMirror im) => im.reflectee is StepDef);
          Future.forEach(filteredMetadata, (InstanceMirror im) {
            _log.debug(im.reflectee.verbiage);
            stepRunners[new RegExp(im.reflectee.verbiage)] = (ctx, params, Map namedParams) {
              _log.debug("Executing ${mm.simpleName} with params: ${[ctx, params]} named: ${namedParams}");
              var converted = namedParams.keys.map((key) => new Symbol(key));
              lib.invoke(mm.simpleName, [ctx, params], new Map.fromIterables(converted, namedParams.values));
            };
          });
        });
      });
    });
  }).whenComplete(() => comp.complete(stepRunners));

  return comp.future;
}


/// Do any of the [tags] match one of [expectedTags] ?
/// If [expectedTags] is empty, anything matches.
bool _tagsMatch(tags, expectedTags) {
  return expectedTags.isEmpty || tags.any((element) => expectedTags.contains(element));
}

