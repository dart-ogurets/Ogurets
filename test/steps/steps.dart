library dherkin_stepdefs_steps1;

import 'package:ogurets/ogurets.dart';

class SampleSteps {

  @Given("I have a parameterized statement with param {string}")
  i_have_a_parameterized_statement_with_param(String param, StringBuffer out) {
    out.writeln("Param step $param");
  }

  @Given("I have a parameterized table")
  i_have_a_parameterized_table(GherkinTable table, StringBuffer out, Map<dynamic, dynamic> exampleRow) {
    out.writeln("Table step $table");
    // Fail if there are any placeholders left...
    assert(table.gherkinRows()[1].contains('<') == false);
  }

  @Given(r'this step fails with an exception')
  void thisStepFails() async {
    throw Exception('step failed');
  }

  @Before(tag: 'FailedSetup')
  void failedSetup() {
    throw Exception('setup failed');
  }

  @Given("I have a {string} with {float}")
  void strFloat(String s, num f) {
    // do nothing...
  }
}

/// Session class to be injected in our step definition class
class FailingSession {

  int counter = 0;

  FailingSession() {
    throw Exception('Cannot create session for some reason');
  }
}

class SessionSteps {

  final FailingSession session;

  SessionSteps(this.session);

  @Given(r'Just a step that works with a session object')
  void justAStepThatWorksWithASessionObject() async {
    print('Counter: ${session.counter}');
  }
}
