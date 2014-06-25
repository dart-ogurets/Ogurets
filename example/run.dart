library dherkin_example;

import "package:log4dart/log4dart.dart";
import 'package:dherkin/dherkin.dart';

import 'steps/steps1.dart';
import 'steps/py_strings.dart';

void main(args) {
  run(args).whenComplete(() => print("ALL DONE"));
}
