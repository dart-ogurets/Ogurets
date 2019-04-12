part of dherkin_core3;

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
