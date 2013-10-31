part of dherkin;

class StepdefScanner {
  static final _log = LoggerFactory.getLoggerFor(GherkinParser);

  Future<Map> scan() {

    Map stepRunners = {};

    Completer comp = new Completer();
    Future.forEach(currentMirrorSystem().libraries.values, (LibraryMirror lib) {
      return new Future.sync(() {
        Future.forEach(lib.functions.values, (MethodMirror mm) {
          return new Future.sync(() {
            var filteredMetadata = mm.metadata.where((InstanceMirror im) => im.reflectee is StepDef);
            Future.forEach(filteredMetadata, (InstanceMirror im) {
              _log.debug(mm.simpleName.toString());
              _log.debug(im.reflectee.verbiage);

              stepRunners[im.reflectee.verbiage] = (ctx) {
                lib.invoke(mm.simpleName, [ctx]);
              };
            });
          });
        });
      });
    }).whenComplete(() => comp.complete(stepRunners));

    return comp.future;
  }
}
