

import 'package:ogurets/ogurets.dart';

// ignore: avoid_relative_lib_imports
import '../lib/hooks.dart';
// ignore: avoid_relative_lib_imports
import '../steps/expressions.dart';

void main() async {
  var def = OguretsOpts()
    ..step(Expressions)
    ..hooks(Hooks)
    ..feature("example/gherkin/cuke_expression.feature")
    ..debug()
  ;

  await def.run();
}