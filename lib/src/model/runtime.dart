part of '../../ogurets.dart';

class StepDefUndefined implements Exception {}

class StepFailure {
  Exception? error;
  String? trace;

  StepFailure(Object e, String? s) {
    if (e is Exception) {
      error = e;
    } else {
      error = Exception(e.toString());
    }
    trace = s;
  }
  // Note: StackTrace yields Illegal argument in isolate message.
  // maybe Location, too ?
}

class Location {
  String? srcFilePath;
  int srcLineNumber;

  Location(this.srcFilePath, this.srcLineNumber);

  @override
  String toString() {
    return " # $srcFilePath:$srcLineNumber";
  }
}
