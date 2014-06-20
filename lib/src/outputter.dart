part of dherkin_core;

abstract class ResultBuffer {
  void write(message, {color: "white"});
  void writeln(message, {color: "white"});
  void missingStepDef(steps, columnNames);
  void merge(ResultBuffer buffer);
  void flush();
}

class ConsoleBuffer implements ResultBuffer {
  static final ANSI_ESC = "\x1B[";

  static final colors = {
      "black": new AnsiPen()..black(), "red":new AnsiPen()..red(), "green":new AnsiPen()..green(), "white":new AnsiPen()..white(), "yellow" : new AnsiPen()..yellow(), "gray": new AnsiPen()..gray(level: 0.5)};

  Map _columns = {};
  Set<String> _missingStepDefs = new Set();
  StringBuffer _buffer = new StringBuffer();

  String buffer() {
    return _buffer;
  }

  void missingStepDef(step, columnNames) {
    _columns[step] = columnNames;
    _missingStepDefs.add(step);
  }

  void write(message, {color: "white"}) {
    _buffer.write(colors[color](message));
  }

  void writeln(message, {color : "white"}) {
    _buffer.writeln(colors[color](message));
  }

  void merge(ResultBuffer other) {
    if (other is ConsoleBuffer) {
      this._buffer.write(other._buffer);
      this._missingStepDefs.addAll(other._missingStepDefs);
      this._columns.addAll(other._columns);
    } else {
      throw "Tried to merge different types of buffers!  Receiver: ${this.runtimeType.toString()} Other: ${other.runtimeType.toString()}";
    }
  }

  void flush() {
    _log.debug("Flushing");
    print(_buffer.toString());

    _missingStepDefs.forEach((step) {
      var matchString = step.replaceAll(new RegExp("\".+?\""), "\\\"(\\\\w+?)\\\"");
      var columnsVerbiage = _columns[step].length > 0 ? ", {${_columns[step].join(",")}}" : "";
      print(colors["yellow"]("\n@StepDef(\"$matchString\")\n${_generateFunctionName(step)}(ctx, params$columnsVerbiage) {\n// todo \n}\n"));
    });

    _buffer.clear();
    _missingStepDefs.clear();
  }
}

String _generateFunctionName(stepString) {
  var chunks = stepString.replaceAll(new RegExp("\""), "").replaceAll(new RegExp("[<>]"), r"$").split(new RegExp(" "));
  var end = chunks.length > 3 ? 4 : chunks.length;
  return chunks.sublist(0, end).join("_").toLowerCase();
}