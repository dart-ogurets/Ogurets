part of ogurets_core3;

class GherkinParserTask {
  List<String> contents;
  String filePath;

  GherkinParserTask(this.contents, this.filePath);

  /// Returns a Future to a fully populated Feature,
  /// from the Gherkin feature statements in [contents],
  /// which is a List of lines.
  Future<Feature> execute() async {
    Feature feature = GherkinParser().parse(contents, filePath: filePath);
    return feature;
  }
}
