import 'dart:io';

import 'package:test/test.dart';

/// The samples use paths relative to the repository root, as an IDE would run
/// them, so they are run as separate processes from there. That also checks
/// the exit code a real run ends with.
Future<ProcessResult> runSample(
  String sample, {
  List<String> args = const [],
  Map<String, String>? environment,
}) => Process.run(
  Platform.resolvedExecutable,
  ['--enable-asserts', 'example/samples/$sample.dart', ...args],
  workingDirectory: '..',
  environment: environment,
);

void expectExit(ProcessResult result, int code) {
  expect(
    result.exitCode,
    code,
    reason: 'stdout:\n${result.stdout}\nstderr:\n${result.stderr}',
  );
}

void main() {
  test('expression_compare passes and exits 0', () async {
    final result = await runSample('expression_compare');
    expectExit(result, 0);
    expect(result.stdout, contains('Scenarios passed: 1'));
    expect(result.stdout, isNot(contains('Scenarios failed')));
  });

  test('run (table feature) passes and exits 0', () async {
    final result = await runSample('run');
    expectExit(result, 0);
    expect(result.stdout, contains('Scenarios passed: 1'));
    expect(result.stdout, isNot(contains('Scenarios failed')));
  });

  test('missing_step_fail fails on its missing steps and exits 1', () async {
    final result = await runSample('missing_step_fail');
    expectExit(result, 1);
    expect(result.stdout, contains('Missing steps:'));
    expect(result.stdout, contains('Scenarios failed: 4'));
    // the sample throws if the feature did not fail
    expect(result.stderr, isNot(contains('missing steps should be failing')));
  });

  test('--no-fail-on-error keeps a failed run at exit 0', () async {
    final result = await runSample(
      'missing_step_fail',
      args: ['--no-fail-on-error'],
    );
    expectExit(result, 0);
    expect(result.stdout, contains('Scenarios failed: 4'));
  });

  test('OGURETS_FAIL_ON_ERROR=false keeps a failed run at exit 0', () async {
    final result = await runSample(
      'missing_step_fail',
      environment: {'OGURETS_FAIL_ON_ERROR': 'false'},
    );
    expectExit(result, 0);
    expect(result.stdout, contains('Scenarios failed: 4'));
  });

  test('old_style_run (deprecated entry point) passes and exits 0', () async {
    final result = await runSample('old_style_run');
    expectExit(result, 0);
    expect(result.stdout, contains('Scenarios passed: 4'));
  });
}
