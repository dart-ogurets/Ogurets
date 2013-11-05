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

