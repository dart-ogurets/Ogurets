library;

import 'package:ogurets/ogurets.dart';

import 'package:ogurets_examples/hooks.dart';
import 'package:ogurets_examples/shared_instance.dart';
import '../steps/sum.dart';

Future<RunStatus> timerSample() async {
  var def = OguretsOpts()
    ..feature("../example/gherkin/time.feature")
    ..instance(SharedInstance())
    ..step(Sum)
    ..step(Hooks)
    // the feature fails on purpose - keep the test run's exit code clean
    ..failOnError(false);

  return await def.run();
}
