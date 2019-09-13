library ogurets_example;

import 'package:ogurets/ogurets.dart';

import '../lib/shared_instance.dart';
import '../steps/backgrounds.dart';
import '../steps/expressions.dart';
import '../steps/shared_instance_stepdef.dart';
import '../steps/steps1.dart';
import '../steps/sum.dart';

void main(args) async {
  var def = new OguretsOpts()
   ..feature("example/gherkin/table.feature")
   ..debug()
   ..instance(new SharedInstance())
   ..failOnMissingSteps(false)
   ..step(Backgrounds)
   ..step(SharedInstanceStepdef)
   ..step(Expressions)
   ..step(Sum)
   ..step(SampleSteps);

  await def.run();

}
