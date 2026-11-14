import 'package:ogurets/ogurets.dart';

import '../steps/output_steps.dart';

/// Runs the step output feature to the console, for step_output_test.dart.
Future<void> main(List<String> args) async {
  await (OguretsOpts()
        ..feature('test/features/step_output.feature')
        ..failOnError(false)
        ..step(OutputSteps))
      .run(args: args);
}
