Feature: timer feature

  @TimerTag
  Scenario Outline: Using integers in examples
    Given I add <amt1>
    And I add <amt2>
    Then the total should be <total>
    Examples:
      | amt1 | amt2 | total |
      | 4    | 3    | 7    |
