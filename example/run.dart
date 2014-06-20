library dherkin_example;

import "package:log4dart/log4dart.dart";
import '../lib/dherkin.dart';

void main(args) {
  //args = ["gherkin/everything.feature","gherkin/pystrings.feature","gherkin/test_feature.feature"];
  run(args).whenComplete(() => print("ALL DONE"));
}

/// ----------------------------------------------------------------------------

@StepDef("parser is working")
step1(ctx, params) {
  print("Компрессия! $ctx");
}

@StepDef("I run dherkin")
i_run_dherkin(ctx, params) {
  print("УРА!");
  throw "блин";
}

@StepDef("everything \"(\\w+?)\"")
everything_works(ctx, params) {
  print("Everything Works $params");
}

@StepDef("I run some background")
i_run_some(ctx, params) {
  print("I run some background");
}

@StepDef("I have a table")
i_have_a_table(ctx, params) {
  print("Table1 $ctx $params");
}

@StepDef("I am a step after the table")
i_am_a_step(ctx, params) {
  print("Table2 $ctx $params");
}

@StepDef("I am a table step \"(\\w+?)\"")
i_am_a_table_step(ctx, params) {
  print("Table3 $ctx $params");
}

@StepDef("everything works just fine")
everything_works_just(ctx, params) {
  print("Table4 $ctx $params");
}

@StepDef("I evaluate <column2>")
i_evaluate_$column2$(ctx, params, {column1, column2}) {
  print("COLUMN 2 $ctx $column2");
}

@StepDef("I read <column1>")
i_read_$column1$(ctx, params, {column1, column2}) {
  print("Columns are working $column1 $column2");
}


/// PyStrings ------------------------------------------------------------------

List stepParameters;
String expectedPyString = """
line 1
line 2
""";

@StepDef("I have the following PyString:")
i_have_the_following_pystring(ctx, params) {
  stepParameters = params;
}

@StepDef("the above Step should have the PyString as last parameter.")
the_above_stepdef_should_have_the_pystring(ctx, params) {
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

