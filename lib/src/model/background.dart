part of dherkin_core;

class Background extends Scenario {
  // todo: Fetch this from GherkinVocabulary or something
  String gherkinKeyword = "Background";
  //bool bufferIsMerged = false;

  Background(name, location) : super (name, location);
}
