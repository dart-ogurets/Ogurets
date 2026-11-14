part of '../../ogurets.dart';

class GherkinBackground extends GherkinScenario {
  // todo: Fetch this from GherkinVocabulary or something
  //bool bufferIsMerged = false;

  GherkinBackground(super.name, super.location) {
    gherkinKeyword = "Background";
  }
}
