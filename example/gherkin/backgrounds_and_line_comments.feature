Feature: Supporting Backgrounds and Comments

  # Note: inlined comments are not supported in gherkin.

  # Backgrounds are written to buffer only once,
  # but executed once per scenario (outline example).

  Background:
    Given I have a background setting a variable to a default value

  Scenario: First Scenario
    Given I set the background-setup variable to a different value
     Then the background-setup variable should hold the different value

  Scenario: Second Scenario
    Given this scenario has ran the background first
     Then the background-setup variable should hold the default value

  Scenario Outline: With each example of an outline
    Given this scenario outline example has ran the background first
     Then the background-setup variable should hold the default value
      And I set the background-setup variable to a different value
  Examples:
    |col1|col2 |
    |imus|nocte|
    |igni|genus|

# Scenario: Commented Scenario
#   Given this is a commented scenario
#    Then this step should never run