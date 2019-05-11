library ogurets_example;

import 'package:ogurets/ogurets.dart';

import 'lib/hooks.dart';
import 'lib/shared_instance.dart';
import 'steps/backgrounds.dart';
import 'steps/expressions.dart';
import 'steps/py_strings.dart';
import 'steps/shared_instance_stepdef.dart';
import 'steps/steps1.dart';
import 'steps/sum.dart';

void main(args) async {
  var def = new OguretsOpts()
    ..feature("example/gherkin/time.feature")
    ..debug()
    ..instance(new SharedInstance())
    ..step(Sum)
    ..step(Hooks);

  await def.run();

}
