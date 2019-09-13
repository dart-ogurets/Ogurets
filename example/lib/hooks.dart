
import 'dart:async';

import 'package:ogurets/ogurets.dart';

import 'scenario_session.dart';

class Hooks {
  @Before()
  void beforeEach(ScenarioSession session, ScenarioStatus tracker) {
    tracker.addendum["before-each"] = true;
    session.sharedStepData['before-all'] = 'here';
  }

  @Before(order: -1)
  void shouldBeAlwaysFirstRun(ScenarioStatus tracker) {
    tracker.addendum["first run?"] = true;
  }

  @After()
  void afterEach(ScenarioSession session, ScenarioStatus tracker) {
    tracker.addendum['after-each'] = true;
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
  void callMeTimer(ScenarioStatus tracker) {
    tracker.addendum["timer check"] = true;
  }

  // should come last
  @After(tag: "TimerTag", order: 90)
  void afterTimer(ScenarioStatus tracker) {
    tracker.addendum["after timer"] = true;
  }

  @AfterStep(order: 10)
  void afterStepCounter(ScenarioStatus tracker) {
    int val = tracker.addendum['after-all-step-counter'] ?? 0;
    val = val + 1;
    tracker.addendum['after-all-step-counter'] = val;
  }

  @BeforeStep(order: 10)
  void beforeStepCounter(ScenarioStatus tracker) {
    int val = tracker.addendum['before-all-step-counter'] ?? 0;
    val = val + 1;
    tracker.addendum['before-all-step-counter'] = val;
  }

  // interfere with the same counter
  @BeforeStep(order: 11, tag: 'TimerBeforeStepHook')
  void beforeStepTimerCounter(ScenarioStatus tracker) {
    int val = tracker.addendum['before-all-step-counter'] ?? 0;
    val = val + 1;
    tracker.addendum['before-all-step-counter'] = val;
  }

  // interfere with same counter
  @AfterStep(order: 11, tag: 'TimerAfterStepHook')
  void afterStepTimerCounter(ScenarioStatus tracker) {
    if (tracker.failedStepsCount == 0) {
      int val = tracker.addendum['after-all-step-counter'] ?? 0;
      val = val + 1;
      tracker.addendum['after-all-step-counter'] = val;
    }
  }



  // should come first
  @After(tag: "TimerTag")
  void afterTimer2(ScenarioStatus tracker) {
    tracker.addendum["after timer2"] = true;
  }

  // should come last (order 0)
  @Before(tag: 'TimerTag')
  Future timerTag(ScenarioStatus tracker) async {
    Duration timeout = const Duration(seconds: 2);

    tracker.addendum["timer started"] = true;
    final completer = Completer();

    Timer(timeout, () {
      tracker.addendum["timer finished"] = true;
      completer.complete();
    });

    return completer.future;
  }

}