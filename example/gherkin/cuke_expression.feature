Feature: Sample expressions

  @CukeExpression
  Scenario: I match each one
    Given I have a "fred" with 1.0
    And A "mary" with 2
    Then "mary" has a value of "2"
    Then "fred" has a value of "1.0"
    