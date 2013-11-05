@Ftag
@Ftag2 @Ftag3 @Ftag4
@feature @feature2 @feature3 Feature: Feature Making sure that parser works

  Background:
    Given I run some background
    And background is fine

  @STAG1
  @STAG2
  @STAG3 @STAG4 Scenario: Scenario Parser is working
    Given parser is working
      |column1|column2|column3|column4|
      |A		|B		|C		|D		|
      |E		|F		|G		|H		|
    When I run dherkin
    And the phase of the moon is "favorable"
    Then everything "works"
    But work still goes on


  @Tables
  Scenario: Tables
    Given I have a table
      |column1|column2|column3|column4|
      |A		|B		|C		|D		|
      |E		|F		|G		|H		|
    And I am a step after the table
    When I am a table step "executed"
      |column1|column2|column3|column4|
      |A		|B		|C		|D		|
      |E		|F		|G		|H		|
    Then everything works just fine