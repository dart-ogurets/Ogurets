Feature: Step output

  Scenario: Passes quietly
    Given a step that writes "quiet" to out
    And a step that prints "quiet"
    And a step that logs "quiet"

  Scenario: Fails loudly
    Given a step that writes "earlier" to out
    When a step that writes, prints and logs "loud" and fails

  @NoisyHook
  Scenario: Fails in a noisy hook
    Given a step that prints "after-hook"
