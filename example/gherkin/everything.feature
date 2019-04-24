@Production
Feature: Making sure that parser works

  Background:
    Given I run some background

  @BUG_123
  Scenario: Parser is working
    Given parser is working
    When I run dherkin
    And the phase of the moon is "favorable"
    Then everything "works"

  Scenario Outline:  Outline Some examples
    Given I read another "<column1>"
    And I evaluate "<column2>"
    And Shared instance count is still 1
  Examples:
    | column1 | column2 |
    | hello   | world   |
    | hello   | world   |
    | hello   | world   |


  Scenario Outline: Using integers in examples
    Given I add <amt1>
    And I add <amt2>
    Then the total should be <total>
    Examples:
    | amt1 | amt2 | total |
    | 4    | 3    | 7    |
    | -1   | 8    | 7    |

  @Tables
  Scenario: Tables
    Given I have a table
      | column1 | column2 | column3 | column4 |
      | A       | B       | C       | D       |
      | E       | F       | G       | H       |
    And I am a step after the table
    When I am a "table" step executed
      | column1 | column2 | column3 | column4 |
      | A       | B       | C       | D       |
      | E       | F       | G       | H       |
    Then everything works just fine
