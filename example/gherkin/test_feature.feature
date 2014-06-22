@Ftag
@Ftag2 @Ftag3 @Ftag4
@feature @feature2 @feature3 Feature: Basic Parser

  Background:
    Given I run some background
    And background is fine

  @STAG1
  @STAG2
  @STAG3 @STAG4 Scenario: First one
    Given I am a step with a table
      | column1 | column2 | column3 | column4 |
      | A       | B       | C       | D       |
      | E       | F       | G       | H       |
    When I run dherkin
    And the "phase" of the "moon" is "favorable"
    Then everything "works"
    But work still goes on


  @Tables
  Scenario: Tables
    Given I have a table
      | column1 | column2 | column3 | column4 |
      | A       | B       | C       | D       |
      | E       | F       | G       | H       |
    And I am a step after the table
    When I am a table step "executed"
      | column1 | column2 | column3 | column4 |
      | Z       | 6       | 5       | 4       |
      | Z       | 1       | 2       | 3       |
    Then everything works just fine

  @Example
  Scenario Outline:  Outline with a table step
    Given I read <column1>
    And I evaluate table with example <column2>
      | column1 | column2 | column3 | column4 |
      | A       | B       | C       | D       |
      | E       | F       | G       | H       |
  Examples:
    | column1 | column2 |
    | hello   | world   |
    | goodbye | world   |