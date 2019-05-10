part of ogurets_core3;

class ConsoleBuffer implements ResultBuffer {
  static final ANSI_ESC = "\x1B[";

  static final colors = {
    "black": new AnsiPen()..black(), "red":new AnsiPen()..red(), "green":new AnsiPen()..green(), "white":new AnsiPen()..white(), "yellow" : new AnsiPen()..yellow(), "gray": new AnsiPen()..gray(level: 0.5), "cyan": new AnsiPen()..cyan(), "magenta": new AnsiPen()..magenta()};

  Map _columns = {};
  StringBuffer _buffer = new StringBuffer();

  StringBuffer buffer() {
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
    _log.fine("Flushing");
    print(_buffer.toString());

    _buffer.clear();
  }
}
