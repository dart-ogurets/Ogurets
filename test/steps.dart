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

}
