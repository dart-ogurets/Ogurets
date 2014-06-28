library dherkin_stepdefs_steps1;

import 'package:dherkin/dherkin.dart';

@Given("parser is working")
step1({out}) {
  out.writeln("Компрессия!");
}

@But("I run dherkin")
i_run_dherkin() {
}

@When("everything \"(\\w+?)\"")
everything_works(worksArg, {out}) {
  out.writeln("Everything Works $worksArg");
}

@Then("I run some background")
i_run_some({out}) {
  out.writeln("I run some background");
}

@StepDef("I have a table")
i_have_a_table({out, table}) {
  out.writeln("Table step");
}

@StepDef("I am a step after the table")
i_am_a_step_after({out}) {
  out.writeln("Table2");
}

i_am_a_table_step({out}) {
  out.writeln("Table3");
}

@StepDef("everything works just fine")
everything_works_just({out}) {
  out.writeln("Table4");
}

@StepDef("I evaluate <column2>")
i_evaluate_$column2$({column1, column2, out}) {
  out.writeln("COLUMN 2 $column2");
}

@StepDef("I evaluate table with example <column2>")
i_evaluate_table_with({ column1, column2, column3, column4, table, out }) {
  out.writeln("Step with table on scenario with example");
  out.writeln("TABLE: $table");
}

@And("I am a table step \"(\\w+?)\"")
i_am_a_table(arg1, {table}) {
}

@StepDef("the \"(\\w+?)\" of the \"(\\w+?)\" is \"(\\w+?)\"")
the_phase_of_the(arg1, arg2, arg3) {

}
@StepDef("I read <column1>")
i_read_$column1$({exampleColumn1, exampleColumn2}) {
}