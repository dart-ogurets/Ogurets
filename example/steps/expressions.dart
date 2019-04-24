

import 'package:dherkin3/dherkin_core.dart';

import '../lib/scenario_session.dart';

class Expressions {
  ScenarioSession _session;
  
  Expressions(this._session);

  @Given("I have a {string} with {float}")
  void strFloat(String s, num f) {
    _session.sharedStepData[s] = f;
  }

  @And("A {string} with {int}")
  void strInt(String s, int i) {
    _session.sharedStepData[s] = i;
  }

//  @Then("{string} has a value of {string}")
  @Then("{string} has a value of {string}")
  void compare(String key, String value) {
    if (value != _session.sharedStepData[key]?.toString()) {
      throw new Exception("failed compare");
    }
  }
}

