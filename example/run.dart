library dherkin_example;

import "package:log4dart/log4dart.dart";
import 'package:dherkin/dherkin.dart';

import 'steps/backgrounds.dart';
import 'steps/py_strings.dart';
import 'steps/steps1.dart';

void main(args) {
  run(args).whenComplete(() => print("ALL DONE"));
}
