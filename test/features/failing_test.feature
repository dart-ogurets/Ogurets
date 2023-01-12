Feature: Make sure failing tests actually result in failed step results


  # The first step will fail, which should result in a failing test.
  Scenario: Failure in given statement
    Given this step fails with an exception


  # This "FailedSetup" will result in an exception in a @Before hook,
  # which should result in a failing test.
  @FailedSetup
  Scenario: Failure in setup
    Given I have a "string" with 12
