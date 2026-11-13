part of '../../ogurets.dart';

abstract class ResultBuffer {
  void write(String? message, {String? color});

  void writeln(String? message, {String? color});

  void merge(ResultBuffer buffer);

  void flush();
}

class ColoredBufferFragment {
  String? color;
  String? contents;

  ColoredBufferFragment(this.contents, this.color);
}

/// The pupose of this buffer is to be merged.
class ColoredFragmentsBuffer implements ResultBuffer {
  List<ColoredBufferFragment> fragments = [];

  @override
  void write(String? message, {String? color}) {
    fragments.add(ColoredBufferFragment(message, color));
  }

  @override
  void writeln(String? message, {String? color}) {
    write("${message ?? ""}\n", color: color);
  }

  @override
  void merge(ResultBuffer buffer) {
    if (buffer is ColoredFragmentsBuffer) {
      fragments.addAll(buffer.fragments);
    } else {
      throw UnsupportedError("Can only merge another ColoredBuffer.");
    }
  }

  @override
  void flush() {
    throw UnsupportedError("ColoredBuffer does not flush().");
  }
}
