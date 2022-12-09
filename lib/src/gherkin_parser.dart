part of ogurets;

RegExp tagsPattern = RegExp(r"(@[^@\r\n\t ]+)");
RegExp featurePattern = RegExp(r"\s*Feature\s*:\s*(.+)");
RegExp scenarioPattern = RegExp(r"^\s*Scenario\s*(?:Outline)?:\s*(.+)\s*$");
RegExp backgroundPattern = RegExp(r"^\s*Background\s*:\s*(.*)\s*$");
RegExp commentPattern = RegExp(r"^\s*#");
RegExp examplesPattern = RegExp(r"^\s*Examples\s*:\s*");
RegExp tablePattern = RegExp(r"\|?\s*([^|\s]+?)\s*\|\s*");
RegExp stepPattern =
    RegExp(r"^\s*(given|when|then|and|but)\s+(.+)", caseSensitive: false);
RegExp pyStringPattern = RegExp(r'^\s*("""|```)\s*$');

/// Could this hold the above regexes and misc vocabulary, so
/// that we can let user provide his, for I18N and other uses ?
/// Note: statics are not suited for inheritance, and it'd be nice
///       to be able to extend this and override only what we want.
class GherkinVocabulary {}

class GherkinSyntaxError extends StateError {
  GherkinSyntaxError(String msg) : super(msg);
}

class _GherkinParser {
  /// Returns a fully populated Feature,
  /// from the Gherkin feature statements in [contents].
  /// If [contents] come from a File, you may provide a [filePath]
  /// that will be used as helper in the output.
  _Feature? parse(Logger log, List<String> contents, {filePath}) {
    _Feature? feature;
    _Scenario? currentScenario;
    _Step? currentStep;
    late GherkinTable currentTable;
    String pyString;

    List<String?> tags = [];

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
        log.fine("Adding tag: ${match.group(1)}");
        tags.add(match.group(1));
      }

      //  Feature
      iter = featurePattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        log.fine("Adding feature: ${match.group(1)}");
        feature = _Feature(match.group(1), Location(filePath, lineCounter));
        feature.tags = tags;
        tags = [];
      }

      //  Scenario
      iter = scenarioPattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        log.fine("Adding scenario: ${match.group(1)}");
        currentScenario =
            _Scenario(match.group(1), Location(filePath, lineCounter));

        //Add all of our feature tags to the scenario, since they apply to each
        if (feature!.tags!.isNotEmpty) {
          tags = [...feature.tags!, ...tags];
        }

        currentScenario.tags = tags;

        feature.scenarios.add(currentScenario);
        tags = [];
      }

      //  Background
      iter = backgroundPattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        log.fine("Adding background: ${match.group(1)}");
        currentScenario =
            _Background(match.group(1), Location(filePath, lineCounter));
        feature!.background = currentScenario;
      }

      //  Steps
      iter = stepPattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        var match = iter.current;
        currentStep = _Step(match.group(1), match.group(2),
            Location(filePath, lineCounter), currentScenario);
        currentTable = currentStep.table;
        currentScenario!.addStep(currentStep);
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
          currentStep!.pyString = pyString;
        } else {
          throw GherkinSyntaxError("PyString's closing tag not found.");
        }
      }

      //  Examples
      iter = examplesPattern.allMatches(line).iterator;
      while (iter.moveNext()) {
        currentTable = currentScenario!.examples;
      }

      //  Tables
      if (line.trim().startsWith("|") && line.trim().endsWith("|")) {
        List<String> row = line.split("|").map((e) => e.trim()).toList();
        //Need to remove the first and last entries in the list, since they will be empty
        //due to the split
        row.removeAt(0);
        row.removeLast();

        if (row.isNotEmpty) {
          currentTable.addRow(row);
        }
      }
    }

    return feature;
  }
}
