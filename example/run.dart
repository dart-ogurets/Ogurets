library dherkin_example;

import 'package:dherkin3/dherkin.dart';

import 'lib/shared_instance.dart';
import 'steps/backgrounds.dart';
import 'steps/py_strings.dart';
import 'steps/shared_instance_stepdef.dart';
import 'steps/steps1.dart';

void main(args) {
  var def = new DherkinOpts()
   ..feature("example/gherkin")
   ..debug()
   ..instance(new SharedInstance())
   ..step(Backgrounds)
    ..step(SharedInstanceStepdef)
   ..step(SampleSteps);

  def.run();

}
