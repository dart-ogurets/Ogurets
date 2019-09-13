library ogurets_example;

import 'package:ogurets/ogurets.dart';

import '../lib/hooks.dart';
import '../lib/shared_instance.dart';
import '../steps/sum.dart';

Future<RunStatus> timerSample() async {
  var def = new OguretsOpts()
    ..feature("../example/gherkin/time.feature")
    ..instance(new SharedInstance())
    ..step(Sum)
    ..step(Hooks);

  return await def.run();

}
