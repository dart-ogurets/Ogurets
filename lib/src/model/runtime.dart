part of dherkin_core;

class StepDefUndefined implements Exception {}

final _NOOP = new Scenario("NOOP", new Location("", -1));

class StepDef {
  final String verbiage;
  const StepDef(this.verbiage);
}

class StepFailure {
  Exception error;
  String trace; // Note: StackTrace yields Illegal argument in isolate message.
// maybe Location, too ?
}

class Location {
  String srcFilePath;
  int srcLineNumber;

  Location(this.srcFilePath, this.srcLineNumber);

  String toString() {
    return " # $srcFilePath:$srcLineNumber";
  }
}