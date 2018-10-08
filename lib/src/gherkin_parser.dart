part of dherkin_core;

RegExp tagsPattern = new RegExp(r"(@[^@\r\n\t ]+)");
RegExp featurePattern = new RegExp(r"\s*Feature\s*:\s*(.+)");
RegExp scenarioPattern = new RegExp(r"^\s*Scenario\s*(?:Outline)?:\s*(.+)\s*$");
RegExp backgroundPattern = new RegExp(r"^\s*Background\s*:\s*(.*)\s*$");
RegExp commentPattern = new RegExp(r"^\s*#");
RegExp examplesPattern = new RegExp(r"^\s*Examples\s*:\s*");
RegExp tablePattern = new RegExp(r"\|?\s*([^|\s]+?)\s*\|\s*");
RegExp stepPattern = new RegExp(r"^\s*(given|when|then|and|but)\s+(.+)", caseSensitive:false);
RegExp pyStringPattern = new RegExp(r'^\s*("""|```)\s*$');


/// Could this hold the above regexes and misc vocabulary, so
/// that we can let user provide his, for I18N and other uses ?
/// Note: statics are not suited for inheritance, and it'd be nice
///       to be able to extend this and override only what we want.
class GherkinVocabulary {}


class GherkinSyntaxError extends StateError {
  GherkinSyntaxError(String msg) : super(msg);
}


class GherkinParser {

  /**
   * Returns a fully populated Feature,
   * from the Gherkin feature statements in [contents].
   * If [contents] come from a File, you may provide a [filePath]
   * that will be used as helper in the output.
   */
  Feature parse(List<String> contents, { filePath }) {
    Logger.root.level = Level.INFO;

    Feature feature;
    Scenario currentScenario;
    Step currentStep;
    GherkinTable currentTable;
    String pyString;

    List<String> tags = [];

    var lineIter = contents.iterator;
    var lineCounter = 0;
    while (lineIter.moveNext()) {
      var line = lineIter.current;
      lineCounter++;

      // Comments
      if (commentPattern.hasMatch(line)) {
        continue;
      }

      //  Tags
      var iter = tagsPattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        _log.fine(match.group(1));
        tags.add(match.group(1));
      }

      //  Feature
      iter = featurePattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        _log.fine(match.group(1));
        feature = new Feature(match.group(1), new Location(filePath, lineCounter));
        feature.tags = tags;
        tags = [];
      }

      //  Scenario
      iter = scenarioPattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        _log.fine(match.group(1));
        currentScenario = new Scenario(match.group(1), new Location(filePath, lineCounter));
        currentScenario.tags = tags;
        feature.scenarios.add(currentScenario);
        tags = [];
      }

      //  Background
      iter = backgroundPattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        _log.fine("Background: ${match.group(1)}");
        currentScenario = new Background(match.group(1), new Location(filePath, lineCounter));
        feature.background = currentScenario;
      }

      //  Steps
      iter = stepPattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        currentStep = new Step(match.group(1), match.group(2), new Location(filePath, lineCounter), currentScenario);
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
          throw new GherkinSyntaxError("PyString's closing tag not found.");
        }
      }

      //  Examples
      iter = examplesPattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        currentTable = currentScenario.examples;
      }

      //  Tables
      List<String> row = [];
      iter = tablePattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        row.add(match[1]);
      }
      if (!row.isEmpty) {
        currentTable.addRow(row);
      }

    }

    return feature;
  }
}