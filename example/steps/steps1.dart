library dherkin_stepdefs_steps1;

import 'package:ogurets/ogurets.dart';

class SampleSteps {
  @Given("parser is working")
  step1({out}) {
    out.writeln("Компрессия!");
  }

  @But("I run dherkin")
  i_run_dherkin() {}

  @When("everything \"(\\w+?)\"")
  everything_works(worksArg, StringBuffer out) {
    out.writeln("Everything Works $worksArg");
  }

  @Then("I run some background")
  i_run_some(out) {
    out.writeln("I run some background");
  }

  @Then("I have a table")
  i_have_a_table(GherkinTable table) {
    // out.writeln("Table step $table");
  }

  @Then("I am a step after the table")
  i_am_a_step_after(StringBuffer out) {
    out.writeln("Table2");
  }

  i_am_a_table_step({out}) {
    out.writeln("Table3");
  }

  @Then("everything works just fine")
  everything_works_just(StringBuffer out) {
    out.writeln("Table4");
  }

  @Then("I evaluate {string}")
  i_evaluate_$column2$(String eval, {exampleRow, out}) {
    out.writeln("ROW: $exampleRow");
  }

  @StepDef("I {string} table with example {string}")
  i_evaluate_table_with(String verb, String col2, {exampleRow, table, out}) {
    out.writeln("Step with table on scenario with example");
    out.writeln("TABLE: $table");
  }

  @And("I am a table step \"(\\w+?)\"")
  i_am_a_table(arg1, {table}) {}

  @StepDef("the \"(\\w+?)\" of the \"(\\w+?)\" is \"(\\w+?)\"")
  the_phase_of_the(arg1, arg2, arg3) {}

  @StepDef("I read {string}")
  i_read_$column1$(String name, {out}) {
    out.writeln("I'm reading a ${name}");
  }

  @StepDef("I read another {string}")
  i_read_another_$column1$(String name, {out}) {
    out.writeln("I'm reading another ${name}");
  }

  @StepDef("I am a \"(\\w+?)\" step executed")
  i_am_a_table_step2(arg1, {table, out}) {
    out.writeln("$arg1 $table");
  }
}
