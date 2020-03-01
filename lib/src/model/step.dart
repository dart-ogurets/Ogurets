part of ogurets_core3;

class Step {
  String verb;
  String verbiage;
  String pyString;
  Scenario scenario;
  GherkinTable table = GherkinTable();
  Location location;
  bool hook;

  String get boilerplate => _generateBoilerplate();

  Step(this.verb, this.verbiage, this.location, this.scenario, {this.hook = false});

  // replace all instances of <column1> with 3 where example data has it as such
  String decodeVerbiage(Map exampleRow) {
    var text = verbiage;

    exampleRow.forEach((k, v) {
      text = text.replaceAll('<${k}>', v.toString());
    });

    return text;
  }

  String toString() {
    if (pyString != null) {
      return "$verbiage\n\"\"\"\n$pyString\"\"\"\n$table";
    } else {
      return "$verbiage $table";
    }
  }

  /// Unserializes if int or num, and leaves as-is if neither.
  /// see https://github.com/dkornishev/dherkin/issues/27

  static dynamic unserialize(String parameter) {
    // Int ?
    try {
      var i = int.parse(parameter);
      return i;
    } on FormatException catch (_) {}

    // Num ?
    try {
      var n = num.parse(parameter);
      return n;
    } on FormatException catch (_) {}

    return parameter;
  }

  String _generateBoilerplate() {
    var matchString =
        verbiage.replaceAll(RegExp("\".+?\""), "\\\"(\\\\w+?)\\\"");

    var params = "";
    var counter = 1;
    "w\+\?".allMatches(matchString).forEach((_) {
      params += "arg$counter,";
      counter++;
    });

    params = params.replaceAll(RegExp(",\$"), "");

    var columnsVerbiage = scenario.examples.length > 1
        ? "{exampleRow ${!table.empty ? ", table" : ""}}"
        : "";
    var tableVerbiage = columnsVerbiage.isEmpty && !table.empty
        ? "${params.isNotEmpty && columnsVerbiage.isEmpty ? "," : ""}{table}"
        : "";
    var separator = params.isNotEmpty && columnsVerbiage.isNotEmpty ? ", " : "";
    return ("\n@${verb}(\"$matchString\")\n${_generateFunctionName()}($params$separator$columnsVerbiage$tableVerbiage) {\n  // todo \n}\n");
  }

  String _generateFunctionName() {
    var chunks = verbiage
        .replaceAll(RegExp("\""), "")
        .replaceAll(RegExp("[<>]"), r"$")
        .split(RegExp(" "));
    var end = chunks.length > 4 ? 5 : chunks.length;
    return chunks.sublist(0, end).join("_").toLowerCase();
  }
}
