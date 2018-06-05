part of dherkin_core;

class StepDefUndefined implements Exception {
}

class StepFailure {
  Exception error;
  String trace;
// Note: StackTrace yields Illegal argument in isolate message.
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