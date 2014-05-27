library dherkin;

import "dart:io";
import "dart:async";
import "dart:mirrors";

import 'package:args/args.dart';
import "package:log4dart/log4dart.dart";

part "src/gherkin_model.dart";
part "src/gherkin_parser.dart";
part "src/outputter.dart";

Logger _log = LoggerFactory.getLogger("dherkin");

ResultWriter _writer = new _ConsoleWriter();

var _runTags = [];

final _NOTFOUND = new RegExp("###");
Map _stepRunners = { _NOTFOUND : (ctx, params, named) => throw new StepDefUndefined()};

void run(args) {
  var options = _parseArguments(args);
  
  if(options["tags"] != null) {
    _runTags = options["tags"].split(",");
  }

  // TODO re-init writer based on flags

  var parser = new GherkinParser();

  _scan().then((executors) {
    options.rest.forEach((filePath) {
      var modelCreator = parser.parse(new File(filePath));

      modelCreator.then((feature) {
        if(_tagsMatch(feature.tags)) {
          _log.debug("Executing: $feature");
          feature.execute().whenComplete(() => new Future(() => _writer.flush()));
        } else {
          _log.debug("Skipping: $feature due to no tags matching");
        }
      });
    });
  });
}

  Future _scan() {
    Completer comp = new Completer();
    Future.forEach(currentMirrorSystem().libraries.values, (LibraryMirror lib) {
      return new Future.sync(() {
        Future.forEach(lib.declarations.values, (MethodMirror mm) {
          return new Future.sync(() {
            var filteredMetadata = mm.metadata.where((InstanceMirror im) => im.reflectee is StepDef);
            Future.forEach(filteredMetadata, (InstanceMirror im) {
              _log.debug(im.reflectee.verbiage);

              _stepRunners[new RegExp(im.reflectee.verbiage)] = (ctx, params, Map namedParams) {
                _log.debug("Executing ${mm.simpleName} with params: ${[ctx, params]} named: ${namedParams}");
                var converted = namedParams.keys.map((key) => new Symbol(key));
                lib.invoke(mm.simpleName, [ctx, params], new Map.fromIterables(converted, namedParams.values));
              };
            });
          });
        });
      });
    }).whenComplete(() => comp.complete(""));

    return comp.future;
  }



/**
* Parses command line arguments
*/
ArgResults _parseArguments(args) {
  var argParser = new ArgParser();
  argParser.addFlag('junit', defaultsTo: true);
  argParser.addOption("tags");
  return argParser.parse(args);
}

bool _tagsMatch(tags) {
  return _runTags.isEmpty || tags.any((element) =>_runTags.contains(element));
}