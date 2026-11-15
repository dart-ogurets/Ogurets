import 'package:ogurets/ogurets.dart';
import 'package:test/test.dart';

import 'steps/parameter_type_steps.dart';

class SilentBuffer extends ColoredFragmentsBuffer {
  @override
  void flush() => fragments.clear();
}

OguretsOpts opts() => OguretsOpts()
  ..feature('test/features/parameter_types.feature')
  ..formatters({BasicFormatter(SilentBuffer())})
  ..failOnError(false)
  ..step(ParameterTypeSteps);

void main() {
  setUp(ParameterTypeSteps.received.clear);

  test('custom parameter types are passed to steps transformed', () async {
    final status = await (opts()..parameterType(colorType)).run();

    expect(ParameterTypeSteps.received, [
      Color.red,
      Color.blue,
      3,
      Color.green,
    ]);
    expect(status.passedFeatures, isEmpty); // the second scenario is undefined
    expect(
      status.boilerplate,
      contains(
        '@Given("an undefined step with a {color} pyramid")\n'
        'void anUndefinedStepWithA(Color color)',
      ),
    );
  });

  test('steps using an unregistered parameter type fail to start', () async {
    await expectLater(
      opts().run(),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          allOf(contains('a {color} ball'), contains('color')),
        ),
      ),
    );
  });

  test('parameter types cannot replace a built-in type', () async {
    await expectLater(
      (opts()..parameterType(
            ParameterType<int>(
              'int',
              r'\d+',
              'int',
              (g) => int.parse(g.first!),
            ),
          ))
          .run(),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Cannot register parameter type {int}'),
        ),
      ),
    );
  });
}
