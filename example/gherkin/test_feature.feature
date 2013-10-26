Feature: Making sure that parser works

  Scenario: Parser is working
	Given parser is working
	When I run dherkin
	And the phase of the moon is "favorable"
	Then everything "works"