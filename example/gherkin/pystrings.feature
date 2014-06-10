Feature: Supporting PyStrings
	
	Scenario: Un-indented PyStrings
		Given I have the following PyString:
"""
line 1
line 2
"""
		Then the above Step should have the PyString as last parameter.
