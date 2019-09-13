
import 'package:test/test.dart';
import '../samples/timer.dart' as timer;

void main() {
  test("Timer test should run and pass", () async {
    final status = await timer.timerSample();
    expect(status.passed, false);
    expect(status.passedFeaturesCount, 0);
    expect(status.failedFeaturesCount, 1);
    expect(status.passedScenarios, 2);
    expect(status.failedScenarios, 1);
    var failed = status.failedFeatures[0].failedScenarios[0];
    expect(failed.addendum['before-all-step-counter'], 6);
    expect(failed.addendum['after-all-step-counter'], 5);

    var passedScenario = status.failedFeatures[0].passedScenarios[0];
    
    expect(passedScenario.addendum['timer check'], true);
    expect(passedScenario.addendum['after timer'], true);
    expect(passedScenario.addendum['after timer2'], true);
    expect(passedScenario.addendum['timer started'], true);
    expect(passedScenario.addendum['timer finished'], true);
    expect(passedScenario.addendum['before-all-step-counter'], 3);
    expect(passedScenario.addendum['after-all-step-counter'], 3);
  });
}