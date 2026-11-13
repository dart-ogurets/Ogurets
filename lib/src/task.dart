part of '../ogurets.dart';

class GherkinParserTask {
  List<String> contents;
  String filePath;
  final Logger log;

  GherkinParserTask(this.log, this.contents, this.filePath);

  /// Returns a Future to a fully populated Feature,
  /// from the Gherkin feature statements in [contents],
  /// which is a List of lines.
  ///
  /// Throws [GherkinSyntaxError] if [contents] is not valid Gherkin, and
  /// [GherkinUnsupportedError] if it uses Gherkin that ogurets cannot run yet.
  Future<GherkinFeature?> execute() async {
    return _GherkinParser(log, filePath).parse(contents.join('\n'));
  }
}
