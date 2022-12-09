library ogurets_example;

import 'package:ogurets/ogurets.dart';

// ignore: avoid_relative_lib_imports
import '../lib/shared_instance.dart';
// ignore: avoid_relative_lib_imports
import '../steps/backgrounds.dart';
// ignore: avoid_relative_lib_imports
import '../steps/expressions.dart';
// ignore: avoid_relative_lib_imports
import '../steps/shared_instance_stepdef.dart';
// ignore: avoid_relative_lib_imports
import '../steps/steps1.dart';
// ignore: avoid_relative_lib_imports
import '../steps/sum.dart';

void main(args) async {
  var def = OguretsOpts()
   ..feature("example/gherkin/table.feature")
   ..debug()
   ..logLevel(LogLevel.FINE)
   ..instance(SharedInstance())
   ..failOnMissingSteps(false)
   ..step(Backgrounds)
   ..step(SharedInstanceStepdef)
   ..step(Expressions)
   ..step(Sum)
   ..step(SampleSteps);

  await def.run();

}
