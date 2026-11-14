library;

import 'package:ogurets/ogurets.dart';

import 'package:ogurets_examples/scenario_session.dart';

/// BACKGROUNDS ----------------------------------------------------------------

///
class Backgrounds {
  ScenarioSession session;
  static const String background = 'background';

  Backgrounds(this.session) {
    session.sharedStepData[background] = 'not_set';
  }

  @Given(
    "I have a background setting a variable to a (default|different) value",
  )
  void iHaveABackgroundSettingAVariable(dynamic defaultOrDifferent) {
    iSetTheBackgroundSetupVariable(defaultOrDifferent);
  }

  @When("I set the background-setup variable to a (default|different) value")
  void iSetTheBackgroundSetupVariable(
    dynamic defaultOrDifferent, {
    dynamic col1,
    dynamic col2,
  }) {
    session.sharedStepData[background] = defaultOrDifferent;
  }

  @Given(
    "the background-setup variable should hold the (default|different) value",
  )
  void theBackgroundSetupVariableShouldHold(
    dynamic defaultOrDifferent, {
    dynamic col1,
    dynamic col2,
  }) {
    if (session.sharedStepData[background] == 'not_set') {
      throw Exception("Background was never ran.");
    }
    if (session.sharedStepData[background] != defaultOrDifferent) {
      throw Exception(
        "Background-setup variable holds '${session.sharedStepData[background]}'"
        ", expected '$defaultOrDifferent'.",
      );
    }
  }

  @Given("this scenario(?: outline example)? has ran the background first")
  void thisScenarioHasRanTheBackgroundFirst({dynamic col1, dynamic col2}) {} // gherkin sugar
}
