Feature: Make sure failing setup actually result in failed step results


  # The first step will fail, which should result in a failing test.
  Scenario: Failure in given statement
    Given this step fails with an exception

