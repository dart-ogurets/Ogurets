part of ogurets;

class StepDefUndefined implements Exception {}

class StepFailure {
  Exception? error;
  String? trace;

  StepFailure(e, s) {
    if (e is Exception) {
      this.error = e;
    } else {
      this.error = Exception(e.toString());
    }
    this.trace = s;
  }
// Note: StackTrace yields Illegal argument in isolate message.
// maybe Location, too ?
}

class Location {
  String? srcFilePath;
  int srcLineNumber;

  Location(this.srcFilePath, this.srcLineNumber);

  String toString() {
    return " # $srcFilePath:$srcLineNumber";
  }
}
