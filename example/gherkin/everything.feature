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
		Given I read <column1>
		And I evaluate <column2>
		Examples:
		|column1|column2|
		|hello	|world|
		|goodbye|world|
	
	@Tables	
	Scenario: Tables
	  Given I have a table
        |column1|column2|column3|column4|
        |A		|B		|C		|D		|
        |E		|F		|G		|H		|
      And I am a step after the table
      When I am a table step executed
        |column1|column2|column3|column4|
        |A		|B		|C		|D		|
        |E		|F		|G		|H		|
      Then everything works just fine
