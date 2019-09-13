Feature: timer feature

  @TimerTag
  Scenario Outline: Using integers in examples
    Given I add <amt1>
    And I add <amt2>
    Then the total should be <total>
    Examples:
      | amt1 | amt2 | total |
      | 4    | 3    | 7    |
      | 4    | 9    | 13   |

  @TimerBeforeStepHook @TimerAfterStepHook
  Scenario: This one should fail but the after step hook should still run
    Given I add 3
    And I add 7
    Then the total should be 11