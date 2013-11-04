part of dherkin;

abstract class ResultWriter {
  void missingStepDefs(List<String> steps);
}

class _ConsoleWriter implements ResultWriter {
  void missingStepDefs(steps) {
    print("Step definitions are missing:");
    print(steps.map((stepString) {
      var matchString = stepString.replaceAll(new RegExp("\".+?\""), "\\\"(\\w+?)\\\"");
      return "\n@StepDef(\"$matchString\")\n${_generateFunctionName(stepString)}(ctx, params) {\n// todo \n}\n";
    }).join());
  }
}

class _HtmlWriter implements ResultWriter {

}

String _generateFunctionName(stepString) {
  var chunks = stepString.replaceAll(new RegExp("\""), "").split(new RegExp(" "));
  var end = chunks.length > 2 ? 3 : chunks.length;
  return chunks.sublist(0, end).join("_").toLowerCase();
}