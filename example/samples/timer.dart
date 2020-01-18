library ogurets_example;

import 'package:ogurets/ogurets.dart';

// ignore: avoid_relative_lib_imports
import '../lib/hooks.dart';
// ignore: avoid_relative_lib_imports
import '../lib/shared_instance.dart';
// ignore: avoid_relative_lib_imports
import '../steps/sum.dart';

Future<RunStatus> timerSample() async {
  var def = OguretsOpts()
    ..feature("../example/gherkin/time.feature")
    ..instance(SharedInstance())
    ..step(Sum)
    ..step(Hooks);

  return await def.run();

}
