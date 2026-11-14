import 'dart:io';

import 'package:ogurets/ogurets.dart';
import 'package:test/test.dart';

import 'steps/steps.dart' as steps;

class SilentBuffer extends ColoredFragmentsBuffer {
  @override
  void flush() => fragments.clear();
}

/// Runs the tags feature and returns the names of the scenarios that ran.
Future<List<String?>> ran({String? configured, List<String>? args}) async {
  final opts = OguretsOpts()
    ..feature('test/features/tags.feature')
    ..formatters({BasicFormatter(SilentBuffer())})
    ..step(steps.SampleSteps);
  if (configured != null) {
    opts.tags(configured);
  }
  final status = await opts.run(args: args);
  return [
    for (final f in status.features)
      for (final s in f.passedScenarios) s.scenario!.name,
  ]..sort();
}

/// Runs test/support/tags_runner.dart (configured with `@a`) in a separate
/// process, so the OGURETS_* environment variables can be set.
Future<String> ranInProcess(
  Map<String, String> environment, [
  List<String> args = const [],
]) async {
  final result = await Process.run(Platform.resolvedExecutable, [
    'run',
    '--enable-asserts',
    'test/support/tags_runner.dart',
    ...args,
  ], environment: environment);
  expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  return RegExp(r'RAN: (.*)').firstMatch(result.stdout as String)!.group(1)!;
}

void main() {
  test('no tags runs everything', () async {
    expect(await ran(), ['A', 'B', 'C', 'Untagged']);
  });

  test('configured tags select scenarios', () async {
    expect(await ran(configured: '@a'), ['A']);
  });

  test('--tags adds to the configured tags', () async {
    expect(await ran(configured: '@a', args: ['--tags', '@b']), ['A', 'B']);
  });

  test('--tags is repeatable and accepts --tags=', () async {
    expect(
      await ran(configured: '@a', args: ['--tags=@b', '--tags', ' @c , @b ']),
      ['A', 'B', 'C'],
    );
  });

  test('--tags works without configured tags', () async {
    expect(await ran(args: ['--tags', '@c']), ['C']);
  });

  test('--replace-tags uses only the command line tags', () async {
    expect(
      await ran(configured: '@a', args: ['--replace-tags', '--tags', '@b']),
      ['B'],
    );
  });

  test('--replace-tags without --tags drops the configured tags', () async {
    expect(await ran(configured: '@a', args: ['--replace-tags']), [
      'A',
      'B',
      'C',
      'Untagged',
    ]);
  });

  test('unknown arguments are ignored', () async {
    expect(
      await ran(
        configured: '@a',
        args: ['--verbose', '-x', 'some-file', '--tags', '@b', '--name=x'],
      ),
      ['A', 'B'],
    );
  });

  test('OGURETS_TAGS adds to the configured and command line tags', () async {
    expect(await ranInProcess({'OGURETS_TAGS': '@c'}), 'A,C');
    expect(
      await ranInProcess({'OGURETS_TAGS': '@c'}, ['--tags', '@b']),
      'A,B,C',
    );
  });

  test('OGURETS_REPLACE_TAGS replaces the configured tags', () async {
    expect(
      await ranInProcess({
        'OGURETS_TAGS': '@c',
        'OGURETS_REPLACE_TAGS': 'true',
      }),
      'C',
    );
  });
}
