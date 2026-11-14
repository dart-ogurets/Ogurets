import 'dart:io';

import 'package:ogurets/ogurets.dart';
import 'package:ogurets_examples/factory_instance.dart';
import 'package:ogurets_examples/hooks.dart';
import 'package:ogurets_examples/shared_instance.dart';
import 'package:test/test.dart';

import '../steps/backgrounds.dart';
import '../steps/expressions.dart';
import '../steps/factory_instance_stepdef.dart';
// top level step functions are found in any loaded library
// ignore: unused_import
import '../steps/py_strings.dart';
import '../steps/shared_instance_stepdef.dart';
import '../steps/steps1.dart';
import '../steps/sum.dart';

/// "Shared instance count is still 1" checks that only one [SharedInstance]
/// was ever created, so every run in this file shares this one.
final sharedInstance = SharedInstance();

/// Runs [features] with every step definition and hook in the examples.
Future<RunStatus> runFeatures(List<String> features) =>
    (OguretsOpts()
          ..features(features)
          // several of these features fail on purpose; don't fail the test run
          ..failOnError(false)
          ..instance(sharedInstance)
          ..instance(FactoryInstance.create())
          ..step(Backgrounds)
          ..step(Expressions)
          ..step(FactoryStepdefs)
          ..step(SharedInstanceStepdef)
          ..step(SampleSteps)
          ..step(Sum)
          ..step(Hooks))
        .run();

class Expected {
  final int passed;
  final int failed;
  final int undefined;
  final String why;

  const Expected(
    this.passed, {
    this.failed = 0,
    this.undefined = 0,
    this.why = '',
  });
}

/// How each feature in gherkin/ is expected to finish.
const expectations = {
  'backgrounds_and_line_comments.feature': Expected(4),
  'cuke_expression.feature': Expected(1),
  'everything.feature': Expected(
    6,
    failed: 1,
    undefined: 1,
    why: '"the phase of the moon is" has no step definition',
  ),
  'factory.feature': Expected(1),
  'pystrings.feature': Expected(1),
  'table.feature': Expected(1),
  'test_feature.feature': Expected(
    0,
    failed: 4,
    undefined: 6,
    why: 'shows missing steps and their generated boilerplate',
  ),
  'time.feature': Expected(
    2,
    failed: 1,
    why: 'a failing assertion, to check the after step hooks still run',
  ),
};

void main() {
  test('every example feature has an expectation', () {
    final features = Directory('gherkin')
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .where((f) => f.endsWith('.feature'))
        .toSet();
    expect(features, expectations.keys.toSet());
  });

  expectations.forEach((feature, expected) {
    final description = expected.failed == 0
        ? '$feature passes'
        : '$feature fails as expected: ${expected.why}';

    test(description, () async {
      final status = await runFeatures(['gherkin/$feature']);

      expect(status.passedScenarios, expected.passed, reason: 'passed');
      expect(status.failedScenarios, expected.failed, reason: 'failed');
      expect(status.skippedScenarios, 0, reason: 'skipped');
      expect(
        status.undefinedStepsCount,
        expected.undefined,
        reason: 'undefined',
      );
      expect(status.failed, expected.failed > 0);
      // failOnError(false) leaves the exit code alone
      expect(exitCode, 0);
    });
  });

  test('the whole gherkin folder runs in one go', () async {
    final status = await runFeatures(['gherkin']);
    int total(int Function(Expected e) f) =>
        expectations.values.fold(0, (sum, e) => sum + f(e));

    expect(status.passedScenarios, total((e) => e.passed));
    expect(status.failedScenarios, total((e) => e.failed));
    expect(
      status.failedFeaturesCount,
      expectations.values.where((e) => e.failed > 0).length,
    );
    expect(
      status.passedFeaturesCount,
      expectations.values.where((e) => e.failed == 0).length,
    );
  });
}
