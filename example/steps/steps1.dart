import 'package:dherkin/dherkin.dart';

@StepDef("parser is working")
step1() {
  print("Компрессия!");
}

@StepDef("I run dherkin")
i_run_dherkin() {
  print("УРА!");
}

@StepDef("everything \"(\\w+?)\"")
everything_works(worksArg) {
  print("Everything Works $worksArg");
}

@StepDef("I run some background")
i_run_some() {
  print("I run some background");
}

@StepDef("I have a table")
i_have_a_table({table}) {
  print("Table step");
}

@StepDef("I am a step after the table")
i_am_a_step_after() {
  print("Table2");
}

i_am_a_table_step() {
  print("Table3");
}

@StepDef("everything works just fine")
everything_works_just() {
  print("Table4");
}

@StepDef("I evaluate <column2>")
i_evaluate_$column2$({column1, column2}) {
  print("COLUMN 2 $column2");
}

@StepDef("I read <column1>")
i_read_$column1$({column1, column2}) {
  print("Columns are working $column1 $column2");
}

@StepDef("I evaluate table with example <column2>")
i_evaluate_table_with({ column1, column2, column3, column4, table }) {
  print("Step with table on scenario with example");
  print("TABLE: $table");
}

@StepDef("I am a table step \"(\\w+?)\"")
i_am_a_table(arg1, {table}) {

}

@StepDef("the \"(\\w+?)\" of the \"(\\w+?)\" is \"(\\w+?)\"")
the_phase_of_the(arg1, arg2, arg3) {

}

/// BACKGROUNDS ----------------------------------------------------------------

String background_setup_variable = 'not_set';

@StepDef("I have a background setting a variable to a (default|different) value")
i_have_a_background_setting_a_variable(defaultOrDifferent) {
  i_set_the_background_setup_variable(defaultOrDifferent);
}

@StepDef("I set the background-setup variable to a (default|different) value")
i_set_the_background_setup_variable(defaultOrDifferent, {col1, col2}) {
  background_setup_variable = defaultOrDifferent;
}

@StepDef("the background-setup variable should hold the (default|different) value")
the_background_setup_variable_should_hold(defaultOrDifferent, {col1, col2}) {
  if (background_setup_variable == 'not_set') {
    throw new Exception("Background was never ran.");
  }
  if (background_setup_variable != defaultOrDifferent) {
    throw new Exception("Background-setup variable holds '$background_setup_variable'"+
    ", expected '$defaultOrDifferent'.");
  }
}

@StepDef("this scenario(?: outline example)? has ran the background first")
this_scenario_has_ran_the_background_first({col1, col2}) {} // gherkin sugar
