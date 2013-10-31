part of dherkin;

RegExp tagsPattern = new RegExp(r"(@[^@\r\n\t ]+)");
RegExp featurePattern = new RegExp(r"Feature\s*:\s*(.+)");
RegExp scenarioPattern = new RegExp(r"Scenario\s*:\s*(.+)");
RegExp stepPattern = new RegExp(r"(given|when|then|and|but)\s+(.+)", caseSensitive:false);

class GherkinParser {
  static final _log = LoggerFactory.getLoggerFor(GherkinParser);

  GherkinParser() {}

  Feature<Feature> parse(File file) {

    var feature;
    var currentScenario;

    Completer comp = new Completer();
    file.readAsLines().then((List<String> contents) {
      var tags = [];

      var lineIter = contents.iterator;

      while (lineIter.moveNext()) {
        var line = lineIter.current;

        var iter = tagsPattern.allMatches(line).iterator;
        while (iter.moveNext()) {
          var match = iter.current;
          _log.debug(match.group(1));
          tags.add(match.group(1));
        }

        iter = featurePattern.allMatches(line).iterator;
        while (iter.moveNext()) {
          var match = iter.current;
          _log.debug(match.group(1));
          feature = new Feature(match.group(1));
          feature.tags = tags;
          tags = [];
        }

        iter = scenarioPattern.allMatches(line).iterator;
        while (iter.moveNext()) {
          var match = iter.current;
          _log.debug(match.group(1));
          currentScenario = new Scenario(match.group(1));
          currentScenario.tags = tags;
          feature.scenarios.add(currentScenario);
          tags = [];
        }

        iter = stepPattern.allMatches(line).iterator;
        while (iter.moveNext()) {
          var match = iter.current;
          currentScenario.steps.add(match.group(2));
        }
      }
    }).whenComplete(() =>comp.complete(feature));

    return comp.future;
  }
}
