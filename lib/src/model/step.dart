part of '../../ogurets.dart';

class GherkinStep {
  String? verb;
  String? verbiage;
  String? pyString;
  GherkinScenario? scenario;
  GherkinTable table = GherkinTable();
  Location location;
  bool hook;

  String get boilerplate => _generateBoilerplate();

  GherkinStep(
    this.verb,
    this.verbiage,
    this.location,
    this.scenario, {
    this.hook = false,
  });

  // replace all instances of <column1> with 3 where example data has it as such
  String? decodeVerbiage(String? verbiage, Map exampleRow) {
    var text = verbiage;

    exampleRow.forEach((k, v) {
      text = text!.replaceAll('<$k>', v.toString());
    });

    return text;
  }

  @override
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
    var matchString = verbiage!.replaceAll(
      RegExp("\".+?\""),
      "\\\"(\\\\w+?)\\\"",
    );

    final positional = [
      for (var i = 1; i <= "w+?".allMatches(matchString).length; i++)
        "dynamic arg$i",
    ];
    final named = [
      if (scenario!.examples.length > 1) "dynamic exampleRow",
      if (!table.empty) "GherkinTable? table",
    ];
    final params = [
      ...positional,
      if (named.isNotEmpty) "{${named.join(", ")}}",
    ];

    // `*` steps and non-English keywords have no matching annotation
    const annotations = {"Given", "When", "Then", "And", "But"};
    final annotation = annotations.contains(verb) ? verb : "StepDef";

    return "\n@$annotation(\"$matchString\")\n"
        "void ${_generateFunctionName()}(${params.join(", ")}) {\n"
        "  // todo\n"
        "}\n";
  }

  /// Builds a lowerCamelCase method name from the first five words of the step.
  String _generateFunctionName() {
    final words = verbiage!
        .split(RegExp(r"\s+"))
        .take(5)
        .map((w) => w.replaceAll(RegExp(r"[^A-Za-z0-9]"), "").toLowerCase())
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return "undefinedStep";
    }
    final name =
        words.first +
        words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join();
    return RegExp(r"^[0-9]").hasMatch(name)
        ? "step${name[0].toUpperCase()}${name.substring(1)}"
        : name;
  }
}
