library dherkin_example;

import "package:log4dart/log4dart.dart";
import '../lib/dherkin.dart';

void main(args) {
  //args = ["gherkin/everything.feature","gherkin/pystrings.feature","gherkin/test_feature.feature"];
  run(args).whenComplete(() => print("ALL DONE"));
}

/// ----------------------------------------------------------------------------

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
}

@StepDef("I am a table step \"(\\w+?)\"")
i_am_a_table(arg1, {table}) {

}

@StepDef("the \"(\\w+?)\" of the \"(\\w+?)\" is \"(\\w+?)\"")
the_phase_of_the(arg1, arg2, arg3) {

}

/// PyStrings ------------------------------------------------------------------

List stepParameters;
String expectedPyString = """
line 1
line 2
""";

@StepDef("I have the following PyString:")
i_have_the_following_pystring(params) {
  stepParameters = params;
}

@StepDef("the above Step should have the PyString as last parameter.")
the_above_stepdef_should_have_the_pystring(params) {
  // maybe we could use the matchers/unittest package ? Assertions make sense here.
  if (stepParameters != null && stepParameters.length > 0) {
    String actualPyString = stepParameters.last;
    if (actualPyString != expectedPyString) {
      throw new Exception("PyString was not as expected :\n[actual]\n$actualPyString\n[expected]\n$expectedPyString");
    }
  } else {
    throw new Exception("No parameters were found in above step.");
  }


}

