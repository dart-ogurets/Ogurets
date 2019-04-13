

import 'package:dherkin3/dherkin.dart';

import 'steps/expressions.dart';

void main() async {
  var def = new DherkinOpts()
    ..step(Expressions)
    ..feature("example/gherkin/cuke_expression.feature")
    ..debug()
  ;

  await def.run();
}