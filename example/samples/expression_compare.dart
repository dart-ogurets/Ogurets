

import 'package:ogurets/ogurets.dart';

import '../lib/hooks.dart';
import '../steps/expressions.dart';

void main() async {
  var def = new OguretsOpts()
    ..step(Expressions)
    ..hooks(Hooks)
    ..feature("example/gherkin/cuke_expression.feature")
    ..debug()
  ;

  await def.run();
}