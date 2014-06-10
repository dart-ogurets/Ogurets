part of dherkin;

RegExp tagsPattern = new RegExp(r"(@[^@\r\n\t ]+)");
RegExp featurePattern = new RegExp(r"Feature\s*:\s*(.+)");
RegExp scenarioPattern = new RegExp(r"Scenario\s*(?:Outline)?:\s*(.+)");
RegExp backgroundPattern = new RegExp(r"Background\s*:\s*$");
RegExp examplesPattern = new RegExp(r"Examples\s*:\s*");
RegExp tablePattern = new RegExp(r"\|?\s*([^|\s]+?)\s*\|\s*");
RegExp stepPattern = new RegExp(r"(given|when|then|and|but)\s+(.+)", caseSensitive:false);
RegExp pyStringPattern = new RegExp(r'^"""$');

class GherkinParser {
  static final _log = LoggerFactory.getLoggerFor(GherkinParser);

  Future<Feature> parse(File file) {
    Feature feature;
    Scenario currentScenario;
    Step currentStep;
    GherkinTable currentTable;
    String pyString;

    Completer comp = new Completer();
    file.readAsLines().then((List<String> contents) {
      var tags = [];

      var lineIter = contents.iterator;
      while (lineIter.moveNext()) {
        var line = lineIter.current;

        //  Tags
        var iter = tagsPattern.allMatches(line).iterator;
        while (iter.moveNext()) {
          var match = iter.current;
          _log.debug(match.group(1));
          tags.add(match.group(1));
        }

        //  Feature
        iter = featurePattern.allMatches(line).iterator;
        while (iter.moveNext()) {
          var match = iter.current;
          _log.debug(match.group(1));
          feature = new Feature(match.group(1));
          feature.tags = tags;
          tags = [];
        }

        //  Scenario
        iter = scenarioPattern.allMatches(line).iterator;
        while (iter.moveNext()) {
          var match = iter.current;
          _log.debug(match.group(1));
          currentScenario = new Scenario(match.group(1));
          currentScenario.tags = tags;
          feature.scenarios.add(currentScenario);
          tags = [];
        }

        //  Background
        iter = backgroundPattern.allMatches(line).iterator;
        while (iter.moveNext()) {
          var match = iter.current;
          _log.debug("Background");
          currentScenario = new Scenario("Background");
          feature.background = currentScenario;
        }

        //  Steps
        iter = stepPattern.allMatches(line).iterator;
        while (iter.moveNext()) {
          var match = iter.current;
          currentStep = new Step(match.group(2));
          currentTable = currentStep.table;
          currentScenario.addStep(currentStep);
        }

        //  PyStrings
        if (pyStringPattern.hasMatch(line)) {
          pyString = '';
          bool foundClosingTag = false;
          while (!foundClosingTag && lineIter.moveNext()) {
            line = lineIter.current;
            if (pyStringPattern.hasMatch(line)) {
              foundClosingTag = true;
            } else {
              pyString += line + "\n";
            }
          }
          if (foundClosingTag) {
            currentStep.pyString = pyString;
          } else {
            throw new Exception("Invalid Gherkin : PyString's closing \"\"\" not found.");
          }
        }

        //  Examples
        iter = examplesPattern.allMatches(line).iterator;
        while (iter.moveNext()) {
          var match = iter.current;
          currentTable = currentScenario.examples;
        }

        //  Tables
        var row = [];
        iter = tablePattern.allMatches(line).iterator;
        while (iter.moveNext()) {
          var match = iter.current;
          row.add(match[1]);
        }

        if(!row.isEmpty) {
          currentTable.addRow(row);
        }

      }
    }).whenComplete(() => comp.complete(feature));

    return comp.future;
  }
}