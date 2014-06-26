library dherkin_stepdefs_backgrounds;

import 'package:dherkin/dherkin.dart';

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

