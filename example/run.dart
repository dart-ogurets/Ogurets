library dherkin_example;

import "dart:io";
import "dart:async";
import "dart:mirrors";
import "../lib/dherkin.dart";



void main(args) {
  run(args);

  //var exp = new RegExp("everything \"(\\w+?)\"");
  //print(exp.firstMatch("everything \"works\"").group(1));
}


//***************
@StepDef("parser is working")
step1(ctx, params) {
  print("Компрессия! $ctx");
}

@StepDef("I run dherkin")
i_run_dherkin(ctx, params) {
  print("УРА!");
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