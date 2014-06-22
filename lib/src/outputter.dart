part of dherkin_core;

abstract class ResultBuffer {
  void write(message, {color});
  void writeln(message, {color});
  void merge(ResultBuffer buffer);
  void flush();
}

class ColoredBufferFragment {
  String color;
  String contents;

  ColoredBufferFragment(this.contents, this.color);
}

/// The pupose of this buffer is to be merged.
class ColoredFragmentsBuffer implements ResultBuffer {
  List<ColoredBufferFragment> fragments = [];
  void write(message, { color }) {
    fragments.add(new ColoredBufferFragment(message, color));
  }
  void writeln(message, { color }) {
    write(message + "\n", color: color);
  }
  void merge(ResultBuffer buffer) {
    if (buffer is ColoredFragmentsBuffer) {
      fragments.addAll(buffer.fragments);
    } else {
      throw new UnsupportedError("Can only merge another ColoredBuffer.");
    }
  }
  void flush() {
    throw new UnsupportedError("ColoredBuffer does not flush().");
  }
}

class ConsoleBuffer implements ResultBuffer {
  static final ANSI_ESC = "\x1B[";

  static final colors = {
      "black": new AnsiPen()..black(), "red":new AnsiPen()..red(), "green":new AnsiPen()..green(), "white":new AnsiPen()..white(), "yellow" : new AnsiPen()..yellow(), "gray": new AnsiPen()..gray(level: 0.5)};

  Map _columns = {};
  StringBuffer _buffer = new StringBuffer();

  String buffer() {
    return _buffer;
  }

  void write(message, { color }) {
    if (color != null) {
      _buffer.write(colors[color](message));
    } else {
      _buffer.write(message);
    }
  }

  void writeln(message, { color }) {
    if (color != null) {
      _buffer.writeln(colors[color](message));
    } else {
      _buffer.writeln(message);
    }
  }

  void merge(ResultBuffer other) {
    if (other == null || other == this) {
      return;
    } else if (other is ConsoleBuffer) {
      this._buffer.write(other._buffer);
      this._columns.addAll(other._columns);
    } else if (other is ColoredFragmentsBuffer) {
      for (ColoredBufferFragment fragment in other.fragments) {
        write(fragment.contents, color: fragment.color);
      }
    } else {
      throw "Tried to merge different types of buffers!  Receiver: ${this.runtimeType.toString()} Other: ${other.runtimeType.toString()}";
    }
  }

  void flush() {
    _log.debug("Flushing");
    print(_buffer.toString());

    _buffer.clear();
  }
}


/// Maybe rename this FeatureStatusFuturesCollection and add other responsibilities,
/// like tallying the count of passing/failing features.
class UndefinedStepsBoilerplate {

  List<Future<FeatureStatus>> featureStatusFutures;
  List<Step> missingSteps = [];

  UndefinedStepsBoilerplate(List<Future<FeatureStatus>> this.featureStatusFutures) {
    for (Future<Feature> f in featureStatusFutures) {
      f.then((FeatureStatus featureStatus){
        for (StepStatus stepStatus in featureStatus.undefinedSteps) {
          // make sure we have no duplicates
          if (null == missingSteps.firstWhere((Step step) => step.verbiage == stepStatus.step.verbiage, orElse: ()=>null)) {
            missingSteps.add(stepStatus.step);
          }
        }
      });
    }
  }

  Future<String> toFutureString() {
    Completer c = new Completer();
    String s = '';
    Future.wait(featureStatusFutures).whenComplete((){
      for (Step step in missingSteps) {
        s += step.boilerplate;
      }
      c.complete(s);
    });
    return c.future;
  }

}

