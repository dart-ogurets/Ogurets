#!/usr/bin/env dart

import "dart:io";
import "dart:isolate";

final _STEPS_SRC = "steps";

void main(args) {

  File runFile = new File(".cucumberd");

  runFile.createSync();
  IOSink sink = runFile.openWrite();

  // Scan for sources
  var directory = new Directory(_STEPS_SRC);

  if (directory.existsSync()) {
    directory.list(followLinks: true, recursive: true).where((FileSystemEntity entity) => entity is File && entity.path.endsWith(".dart")).listen((File file) {
      sink.writeln("import '${file.absolute.path}';");
    }).onDone(() {
      sink.writeln("\nvoid main(args) {print('Эврика');}");
      sink.close().whenComplete(() => Isolate.spawnUri(new Uri.file(runFile.absolute.path), args, ""));
    });
  } else {
    print("$directory does not exist");
  }


// -> in --src

// generate runner script that imports all of them

// run the script
}