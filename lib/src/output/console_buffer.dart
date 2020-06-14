part of ogurets;

class ConsoleBuffer implements ResultBuffer {
  static final ANSI_ESC = "\x1B[";

  static final colors = {
    "black": AnsiPen()..black(),
    "red": AnsiPen()..red(),
    "green": AnsiPen()..green(),
    "white": AnsiPen()..white(),
    "yellow": AnsiPen()..yellow(),
    "gray": AnsiPen()..gray(level: 0.5),
    "cyan": AnsiPen()..cyan(),
    "magenta": AnsiPen()..magenta(),
    "blue": AnsiPen()..blue()
  };

  Map _columns = {};
  StringBuffer _buffer = StringBuffer();

  StringBuffer buffer() {
    return _buffer;
  }

  void write(message, {color}) {
    if (color != null) {
      _buffer.write(colors[color](message));
    } else {
      _buffer.write(message);
    }
  }

  void writeln(message, {color}) {
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

    //Print will automatically add a newline
    print(_buffer);

    _buffer.clear();
  }
}
