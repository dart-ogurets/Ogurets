import 'package:ogurets/ogurets.dart';
import 'package:test/test.dart';

import 'steps/steps.dart' as steps;

void main() async {
  test('Failing test steps', () async {
    var def = OguretsOpts()
      ..feature('test/features/failing_test.feature')
      ..debug()
      ..step(steps.SampleSteps);

    final result = await def.run();

    expect(result.failed, true);
    expect(result.failedFeatures.first.failedScenarios.first.failedSteps.length, 1);
  });

  test('Failing test setup', () async {
    var def = OguretsOpts()
      ..feature('test/features/failing_setup.feature')
      ..debug()
      ..step(steps.SampleSteps);

    final result = await def.run();

    expect(result.failed, true);
    expect(result.failedFeatures.first.failedScenarios.first.failedSteps.length, 1);
  });

  test('Failing test session', () async {
    var def = OguretsOpts()
      ..feature('test/features/failing_session.feature')
      ..debug()
      ..step(steps.SessionSteps)
      ..step(steps.FailingSession);

    final result = await def.run();

    expect(result.failed, true);
    expect(result.failedFeatures.first.failedScenarios.first.failedSteps.length, 1);
  });
}
