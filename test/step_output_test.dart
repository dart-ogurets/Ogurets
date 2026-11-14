import 'dart:io';

import 'package:ogurets/ogurets.dart';
import 'package:test/test.dart';

import 'failure_summary_test.dart' show RecordingBuffer;
import 'steps/output_steps.dart';

const feature = 'test/features/step_output.feature';

Future<(RunStatus, RecordingBuffer)> run() async {
  final buffer = RecordingBuffer();
  final status =
      await (OguretsOpts()
            ..feature(feature)
            ..failOnError(false)
            ..formatters({BasicFormatter(buffer)})
            ..step(OutputSteps))
          .run();
  return (status, buffer);
}

String outOf(RunStatus status, String scenario, String step) {
  final scenarioStatus = status.features
      .expand((f) => f.scenarios)
      .firstWhere((s) => s.scenario!.name == scenario);
  return scenarioStatus.executedSteps
      .firstWhere((s) => s.decodedVerbiage!.contains(step))
      .out
      .toString();
}

void main() {
  test('passing steps capture their output but do not show it', () async {
    final (status, buffer) = await run();

    expect(outOf(status, 'Passes quietly', 'writes'), 'quiet-written\n');
    expect(outOf(status, 'Passes quietly', 'prints'), 'quiet-printed\n');
    expect(
      outOf(status, 'Passes quietly', 'logs'),
      'INFO: output_steps: quiet-logged\nINFO: helper: quiet-logged-later\n',
    );

    // nor is the output of a passing step in a failed scenario
    for (final text in ['quiet-', 'earlier-written']) {
      expect(buffer.text, isNot(contains(text)), reason: text);
    }
  });

  test('a failed step shows its out, print and log output', () async {
    final (_, buffer) = await run();
    final text = buffer.text;
    final summary = buffer.summary.map((f) => f.contents).join();

    // shown with the step as it runs, and again in the failure summary
    for (final output in [
      'loud-written',
      'loud-printed',
      'INFO: helper: loud-logged',
    ]) {
      expect(output.allMatches(text).length, 2, reason: output);
      expect(summary, contains('| $output'));
    }

    // in the summary, the output comes before the error
    expect(
      summary.indexOf('Output:'),
      lessThan(summary.indexOf('Exception: noisy step failed')),
    );
    for (final f in buffer.summary) {
      if ((f.contents ?? '').contains('| ')) {
        expect(f.color, 'gray');
      }
    }
  });

  test('a failed hook shows its output', () async {
    final (_, buffer) = await run();
    final summary = buffer.summary.map((f) => f.contents).join();
    expect(summary, contains('| hook-printed'));
    expect(summary, contains('Exception: noisy hook failed'));
  });

  group('console', () {
    Future<String> console(Map<String, String> environment) async {
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        '--enable-asserts',
        'test/support/output_runner.dart',
      ], environment: environment);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      return result.stdout as String;
    }

    test('only failed step output reaches the console', () async {
      final stdout = await console({});
      expect(stdout, isNot(contains('quiet-')));
      expect(stdout, contains('loud-printed'));
      expect(stdout, contains('INFO: helper: loud-logged'));
    });

    test('ALWAYS_SHOW_OUT shows every step\'s output', () async {
      final stdout = await console({'ALWAYS_SHOW_OUT': 'true'});
      expect(stdout, contains('quiet-written'));
      expect(stdout, contains('quiet-printed'));
      expect(stdout, contains('quiet-logged-later'));
      expect(stdout, contains('loud-printed'));
    });

    test('ALWAYS_SHOW_OUT=false still hides passing step output', () async {
      final stdout = await console({'ALWAYS_SHOW_OUT': 'false'});
      expect(stdout, isNot(contains('quiet-')));
    });
  });
}
