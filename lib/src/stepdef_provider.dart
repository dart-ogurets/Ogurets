part of dherkin;

final _NOTFOUND = new RegExp("###");

class StepdefProvider {
  static final _log = LoggerFactory.getLoggerFor(GherkinParser);

  Map _stepRunners = { _NOTFOUND : (ctx, params) => throw new StepDefUndefined()};

  Future<StepdefProvider> scan() {

    Completer comp = new Completer();
    Future.forEach(currentMirrorSystem().libraries.values, (LibraryMirror lib) {
      return new Future.sync(() {
        Future.forEach(lib.functions.values, (MethodMirror mm) {
          return new Future.sync(() {
            var filteredMetadata = mm.metadata.where((InstanceMirror im) => im.reflectee is StepDef);
            Future.forEach(filteredMetadata, (InstanceMirror im) {
              _log.debug(mm.simpleName.toString());
              _log.debug(im.reflectee.verbiage);

              _stepRunners[new RegExp(im.reflectee.verbiage)] = (ctx, params) {
                lib.invoke(mm.simpleName, [ctx, params]);
              };
            });
          });
        });
      });
    }).whenComplete(() => comp.complete(this));

    return comp.future;
  }

  Function locate(step) {
    var found = _stepRunners.keys.firstWhere((key) => key.hasMatch(step), orElse: () => _NOTFOUND);
    return (ctx) {
      var match = found.firstMatch(step);

      var params = [];
      if (match != null) {
        for (var i = 1;i <= match.groupCount;i++) {
          params.add(match[i]);
        }
      }

      _stepRunners[found](ctx,params);
    };
  }
}
