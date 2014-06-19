part of dherkin_base;

abstract class ResultWriter {
  void write(message, {color: "white"});

  void missingStepDef(steps, columnNames);

  void flush();
}

class ConsoleWriter implements ResultWriter {
  static final ANSI_ESC = "\x1B[";

  static final colors = {
      "black":"${ANSI_ESC}30m", "red":"${ANSI_ESC}31m", "green":"${ANSI_ESC}32m", "white":"${ANSI_ESC}37m", "yellow" : "${ANSI_ESC}33m"
  };

  Set<String> _missingStepDefs = new Set();
  Map _columns = {
  };
  StringBuffer _buffer = new StringBuffer();

  void missingStepDef(step, columnNames) {
    _columns[step] = columnNames;
    _missingStepDefs.add(step);
  }

  void write(message, {color : "white"}) {
    _buffer.writeln("${colors[color]}$message${ANSI_ESC}0m");
  }

  void flush() {
    print(_buffer.toString());

    _missingStepDefs.forEach((step) {
      var matchString = step.replaceAll(new RegExp("\".+?\""), "\\\"(\\\\w+?)\\\"");
      var columnsVerbiage = _columns[step].length > 0 ? ", {${_columns[step].join(",")}}" : "";
      print("${ANSI_ESC}33m\n@StepDef(\"$matchString\")\n${_generateFunctionName(step)}(ctx, params$columnsVerbiage) {\n// todo \n}\n${ANSI_ESC}0m");
    });

    _buffer.clear();
    _missingStepDefs.clear();
  }

}

class HtmlWriter implements ResultWriter {
  void flush() {
    throw "not supported yet";
  }

  void missingStepDef(steps, columnNames) {
    throw "not supported yet";
  }

  void write(message, {color: "white"}) {
    throw "not supported yet";
  }
}

String _generateFunctionName(stepString) {
  var chunks = stepString.replaceAll(new RegExp("\""), "").replaceAll(new RegExp("[<>]"), r"$").split(new RegExp(" "));
  var end = chunks.length > 3 ? 4 : chunks.length;
  return chunks.sublist(0, end).join("_").toLowerCase();
}