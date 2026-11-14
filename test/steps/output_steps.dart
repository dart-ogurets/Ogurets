import 'package:logging/logging.dart';
import 'package:ogurets/ogurets.dart';

final _log = Logger('output_steps');

/// Logs from a class that knows nothing about ogurets.
class Helper {
  static final _log = Logger('helper');

  Future<void> work(String message) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    _log.info(message);
  }
}

/// Each step's output is derived from its argument (e.g. `quiet` ->
/// `quiet-written`), so it can be told apart from the step text itself.
class OutputSteps {
  @Given("a step that writes {string} to out")
  void writesToOut(String text, {StringBuffer? out}) {
    out!.writeln('$text-written');
  }

  @Given("a step that prints {string}")
  void prints(String text) {
    print('$text-printed');
  }

  @Given("a step that logs {string}")
  Future<void> logs(String text) async {
    _log.info('$text-logged');
    // still captured after an await, and from other classes
    await Helper().work('$text-logged-later');
  }

  @Given("a step that writes, prints and logs {string} and fails")
  Future<void> noisyFailure(String text, {StringBuffer? out}) async {
    out!.writeln('$text-written');
    print('$text-printed');
    await Helper().work('$text-logged');
    throw Exception('noisy step failed');
  }

  @Before(tag: 'NoisyHook')
  void noisyHook() {
    print('hook-printed');
    throw Exception('noisy hook failed');
  }
}
