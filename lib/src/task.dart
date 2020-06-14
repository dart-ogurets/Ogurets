part of ogurets;

class GherkinParserTask {
  List<String> contents;
  String filePath;

  GherkinParserTask(this.contents, this.filePath);

  /// Returns a Future to a fully populated Feature,
  /// from the Gherkin feature statements in [contents],
  /// which is a List of lines.
  Future<_Feature> execute() async {
    _Feature feature = _GherkinParser().parse(contents, filePath: filePath);
    return feature;
  }
}
