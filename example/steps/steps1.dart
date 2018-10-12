library dherkin_stepdefs_steps1;

import 'package:dherkin2/dherkin.dart';

@Given("parser is working")
step1({out}) {
  out.writeln("Компрессия!");
}

@But("I run dherkin")
i_run_dherkin() {
}

@When("everything \"(\\w+?)\"")
everything_works(worksArg, StringBuffer out) {
  out.writeln("Everything Works $worksArg");
}

@Then("I run some background")
i_run_some(out) {
  out.writeln("I run some background");
}

@StepDef("I have a table")
i_have_a_table(StringBuffer out, GherkinTable table) {
  out.writeln("Table step $table");
}

@StepDef("I am a step after the table")
i_am_a_step_after(StringBuffer out) {
  out.writeln("Table2");
}

i_am_a_table_step({out}) {
  out.writeln("Table3");
}

@StepDef("everything works just fine")
everything_works_just(StringBuffer out) {
  out.writeln("Table4");
}

@StepDef("I evaluate <column2>")
i_evaluate_$column2$({exampleRow,  out}) {
  out.writeln("ROW: $exampleRow");
}

@StepDef("I evaluate table with example <column2>")
i_evaluate_table_with({ exampleRow, table, out }) {
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
i_read_$column1$({exampleRow}) {
}

@StepDef("I read another <column1>")
i_read_another_$column1$({exampleRow }) {
  // todo
}

@StepDef("I am a \"(\\w+?)\" step executed")
i_am_a_table_step2(arg1,{table, out}) {
  out.writeln("$arg1 $table");
}