Feature: Custom parameter types

  Scenario: Custom types are transformed before the step is called
    Given a red ball
    And a regex step with a blue cube
    And 3 green balls

  Scenario: Snippets for missing steps use custom types
    Given an undefined step with a green pyramid
