#!/usr/bin/env dart

import "dart:io";
import "dart:isolate";

final _STEPS_SRC = "example/steps";

void main(args) {
  File runFile = new File(".cucumberd");

  runFile.createSync();
  IOSink sink = runFile.openWrite();

  // Scan for sources
  var directory = new Directory(_STEPS_SRC);

  ReceivePort receiver = new ReceivePort();

  receiver.listen((data) {
    print("DATA");
  }, onDone: () => print("DONE RECEIVER"));

  if (directory.existsSync()) {
    directory.list(followLinks: true, recursive: true).where((FileSystemEntity entity) => entity is File && !entity.path.contains("packages") && entity.path.endsWith(".dart")).listen((FileSystemEntity fileSystemEntity) {
      sink.writeln("import '${fileSystemEntity.absolute.path}';");
    }).onDone(() {
      sink.writeln("import 'dart:io';");
      sink.writeln("import 'package:dherkin2/dherkin.dart';");
      sink.writeln("\nvoid main(args) {run(args).whenComplete(() => exit(0));}");
      sink.close().whenComplete(() => Isolate.spawnUri(new Uri.file(runFile.absolute.path), args, "").then((Isolate iss) {

      }));
    });
  } else {
    print("Source $directory does not exist");
    exit(1);
  }


// -> in --src
}