import 'package:ogurets/ogurets.dart';
import 'package:test/test.dart';

import 'steps/steps.dart' as steps;

/// Records formatter output with its colors instead of printing it.
class RecordingBuffer extends ColoredFragmentsBuffer {
  @override
  void flush() {}

  String get text => fragments.map((f) => f.contents).join();

  /// Fragments written after the "Failed scenarios:" heading.
  List<ColoredBufferFragment> get summary => fragments
      .skipWhile((f) => !(f.contents ?? '').contains('Failed scenarios:'))
      .toList();
}

Future<RecordingBuffer> run(
  String feature, {
  bool failureSummary = true,
  List<String> moreFeatures = const [],
}) async {
  final buffer = RecordingBuffer();
  final opts = OguretsOpts()..feature(feature);
  moreFeatures.forEach(opts.feature);
  await (opts
        ..formatters({BasicFormatter(buffer, failureSummary: failureSummary)})
        ..step(steps.SampleSteps))
      .run();
  return buffer;
}

/// The colors of every summary fragment whose text contains [text].
List<String?> colorsOf(RecordingBuffer buffer, String text) => [
  for (final f in buffer.summary)
    if ((f.contents ?? '').contains(text)) f.color,
];

void main() {
  const feature = 'test/features/failure_summary.feature';

  test('reprints failed scenarios with step colors and the stack trace', () async {
    final buffer = await run(feature);
    final summary = buffer.summary.map((f) => f.contents).join();

    expect(colorsOf(buffer, 'Failed scenarios:'), ['red']);
    expect(summary, contains('Scenario Outline: Fails part way through'));
    expect(summary, contains('Scenario: Fails in a hook'));

    // the example row that failed
    expect(colorsOf(buffer, '|one|'), ['cyan']);

    // background steps are shown under their own heading
    expect(colorsOf(buffer, '  Background:'), ['gray', 'gray']);

    // passed, failed, skipped and undefined steps of the outline
    expect(colorsOf(buffer, 'Given a passing step with "one"'), ['green']);
    expect(colorsOf(buffer, 'When this step fails with an exception'), ['red']);
    expect(colorsOf(buffer, 'Then a passing step'), ['gray']);
    expect(colorsOf(buffer, 'And this step has no definition (undefined)'), [
      'yellow',
    ]);

    // the error in red, followed by the stack trace
    expect(colorsOf(buffer, 'Exception: step failed'), ['red']);
    expect(summary, contains('SampleSteps.thisStepFails'));

    // a failing hook is shown with its error, and the steps after it are skipped
    expect(colorsOf(buffer, 'failedSetup'), contains('red'));
    expect(colorsOf(buffer, 'Exception: setup failed'), ['red']);
    // background step (indented): passed in both scenarios; scenario step: skipped by the hook
    List<String?> exactly(String text) => [
      for (final f in buffer.summary)
        if (f.contents == text) f.color,
    ];
    expect(exactly('\t\t  Given a passing step'), ['green', 'green']);
    expect(exactly('\t\tGiven a passing step'), ['gray']);
  });

  test('passing hooks are left out of the summary', () async {
    final buffer = await run(feature);
    final hookLines = buffer.summary
        .map((f) => f.contents ?? '')
        .where((t) => t.contains(' - '));
    expect(hookLines, everyElement(contains('failedSetup')));
  });

  test('run-wide totals are printed once, after the failed scenarios', () async {
    final buffer = await run(
      feature,
      moreFeatures: ['test/features/test_examples_table.feature'],
    );
    final text = buffer.text;

    // no per-feature tallies any more
    expect('Scenarios passed:'.allMatches(text).length, 1);

    // totals across both features: 2 passing example rows, 2 failed scenarios
    expect(text, contains('Scenarios passed: 2'));
    expect(text, contains('Scenarios failed: 2'));
    expect(text, contains('Features passed: 1'));
    expect(text, contains('Features failed: 1'));

    // order: failed scenarios, then missing steps, then the totals and run time
    final failed = text.indexOf('Failed scenarios:');
    final missing = text.indexOf('Missing steps:');
    final totals = text.indexOf('Scenarios passed:');
    final runTime = text.indexOf('Run time:');
    expect(failed, greaterThanOrEqualTo(0));
    expect(missing, greaterThan(failed));
    expect(totals, greaterThan(missing));
    expect(runTime, greaterThan(totals));
  });

  test('no summary when nothing failed', () async {
    final buffer = await run('test/features/test_examples_table.feature');
    expect(buffer.text, isNot(contains('Failed scenarios:')));
  });

  test('summary can be turned off', () async {
    final buffer = await run(feature, failureSummary: false);
    expect(buffer.text, isNot(contains('Failed scenarios:')));
  });
}
