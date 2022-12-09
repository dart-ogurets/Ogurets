part of ogurets;

class GherkinParserTask {
  List<String> contents;
  String filePath;
  final Logger log;

  GherkinParserTask(this.log, this.contents, this.filePath);

  /// Returns a Future to a fully populated Feature,
  /// from the Gherkin feature statements in [contents],
  /// which is a List of lines.
  Future<_Feature?> execute() async {
    return _GherkinParser().parse(log, contents, filePath: filePath);
  }
}
