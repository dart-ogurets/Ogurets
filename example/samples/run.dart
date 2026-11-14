library;

import 'package:ogurets/ogurets.dart';

import 'package:ogurets_examples/shared_instance.dart';
import '../steps/backgrounds.dart';
import '../steps/expressions.dart';
import '../steps/shared_instance_stepdef.dart';
import '../steps/steps1.dart';
import '../steps/sum.dart';

void main(List<String> args) async {
  var def = OguretsOpts()
    ..feature("example/gherkin/table.feature")
    ..debug()
    ..logLevel(LogLevel.fine)
    ..instance(SharedInstance())
    ..failOnMissingSteps(false)
    ..step(Backgrounds)
    ..step(SharedInstanceStepdef)
    ..step(Expressions)
    ..step(Sum)
    ..step(SampleSteps);

  await def.run(args: args);
}
