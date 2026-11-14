import 'package:ogurets/ogurets.dart';

import 'package:ogurets_examples/hooks.dart';
import '../steps/expressions.dart';

void main(List<String> args) async {
  var def = OguretsOpts()
    ..step(Expressions)
    ..hooks(Hooks)
    ..feature("example/gherkin/cuke_expression.feature")
    ..debug();

  await def.run(args: args);
}
