import 'package:ogurets/ogurets.dart';

import 'package:ogurets_examples/scenario_session.dart';

class Expressions {
  final ScenarioSession _session;

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
      throw Exception("failed compare");
    }
  }
}
