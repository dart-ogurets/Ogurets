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

  /// The parameter types used to generate the [boilerplate], set when the
  /// step turns out to be undefined. The built-in types if not set.
  ParameterTypeRegistry? parameterTypeRegistry;

  static final ParameterTypeRegistry _defaultParameterTypes =
      ParameterTypeRegistry();

  String _generateBoilerplate() {
    final generated = CucumberExpressionGenerator(
      parameterTypeRegistry ?? _defaultParameterTypes,
    ).generateExpressions(verbiage!).first;
    // escape the expression so it is valid inside a double-quoted Dart string
    final matchString = generated.source
        .replaceAll(r"\", r"\\")
        .replaceAll('"', r'\"')
        .replaceAll(r"$", r"\$");

    final parameterNames = generated.parameterNames;
    final positional = [
      for (var i = 0; i < parameterNames.length; i++)
        "${generated.parameterTypes[i].type ?? "dynamic"} ${parameterNames[i]}",
    ];
    final named = [
      if (scenario!.examples.length > 1) "dynamic exampleRow",
      if (!table.empty) "GherkinTable? table",
    ];
    final params = [
      ...positional,
      if (named.isNotEmpty) "{${named.join(", ")}}",
    ];

    // `*` steps and non-English keywords have no matching annotation; any of the
    // keyword annotations matches any step, so suggest @Given
    const annotations = {"Given", "When", "Then", "And", "But"};
    final annotation = annotations.contains(verb) ? verb : "Given";

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
