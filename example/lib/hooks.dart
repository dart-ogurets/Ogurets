
import 'dart:async';

import 'package:ogurets/ogurets.dart';

import 'scenario_session.dart';

class Hooks {
  @Before()
  void beforeEach(ScenarioSession session) {
    print("before-each");
    session.sharedStepData['before-all'] = 'here';
  }

  @Before(order: -1)
  void shouldBeAlwaysFirstRun() {
    print("first run?");
  }

  @After()
  void afterEach(ScenarioSession session) {
    print("after-each");
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

  // should come 1st
  @Before(tag: "TimerTag", order: -1)
  void callMeTimer() {
    print("timer check");
  }

  // should come last
  @After(tag: "TimerTag", order: 90)
  void afterTimer() {
    print("after timer");
  }

  // should come first
  @After(tag: "TimerTag")
  void afterTimer2() {
    print("after timer2");
  }

  // should come last (order 0)
  @Before(tag: 'TimerTag')
  Future timerTag() async {
    Duration timeout = const Duration(seconds: 5);

    print("timer started");
    final completer = Completer();

    Timer(timeout, () {
      print("timer finished");
      completer.complete();
    });

    return completer.future;
  }

}