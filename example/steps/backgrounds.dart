library dherkin_stepdefs_backgrounds;

import 'package:ogurets/ogurets.dart';

// ignore: avoid_relative_lib_imports
import '../lib/scenario_session.dart';

/// BACKGROUNDS ----------------------------------------------------------------

///
class Backgrounds {
  ScenarioSession session;
  static const String background = 'background';

  Backgrounds(this.session) {
    session.sharedStepData[background] = 'not_set';
  }

  @StepDef(
      "I have a background setting a variable to a (default|different) value")
  i_have_a_background_setting_a_variable(defaultOrDifferent) {
    i_set_the_background_setup_variable(defaultOrDifferent);
  }

  @StepDef("I set the background-setup variable to a (default|different) value")
  i_set_the_background_setup_variable(defaultOrDifferent, {col1, col2}) {
    session.sharedStepData[background] = defaultOrDifferent;
  }

  @StepDef(
      "the background-setup variable should hold the (default|different) value")
  the_background_setup_variable_should_hold(defaultOrDifferent, {col1, col2}) {
    if (session.sharedStepData[background] == 'not_set') {
      throw Exception("Background was never ran.");
    }
    if (session.sharedStepData[background] != defaultOrDifferent) {
      throw Exception(
          "Background-setup variable holds '${session.sharedStepData[background]}'" +
              ", expected '$defaultOrDifferent'.");
    }
  }

  @StepDef("this scenario(?: outline example)? has ran the background first")
  this_scenario_has_ran_the_background_first({col1, col2}) {} // gherkin sugar
}
