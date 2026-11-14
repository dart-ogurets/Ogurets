import 'package:ogurets/ogurets.dart';

import '../steps/steps.dart' as steps;

/// Runs test/features/tags.feature with `..tags('@a')` configured, passing the
/// command line through, and prints the names of the scenarios that ran.
/// Used by tags_test.dart to exercise the OGURETS_* environment variables.
Future<void> main(List<String> args) async {
  final status =
      await (OguretsOpts()
            ..feature('test/features/tags.feature')
            ..tags('@a')
            ..formatters({BasicFormatter(_Silent())})
            ..step(steps.SampleSteps))
          .run(args: args);

  final ran = [
    for (final f in status.features)
      for (final s in f.passedScenarios) s.scenario!.name,
  ]..sort();
  print('RAN: ${ran.join(',')}');
}

class _Silent extends ColoredFragmentsBuffer {
  @override
  void flush() => fragments.clear();
}
