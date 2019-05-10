
import 'package:ogurets/ogurets.dart';

import 'scenario_session.dart';

class Hooks {
  @Before()
  void beforeEach(ScenarioSession session) {
    session.sharedStepData['before-all'] = 'here';
  }

  @After()
  void afterEach(ScenarioSession session) {
    session.sharedStepData['after-all'] = 'here';
  }

  @Before(tag: 'CukeExpression')
  void beforeExpression(ScenarioSession session) {
    session.sharedStepData['before-expr'] = 'here';
  }

  @After(tag: 'CukeExpression')
  void afterExpression(ScenarioSession session) {
    session.sharedStepData['after-expr'] = 'here';
  }

}