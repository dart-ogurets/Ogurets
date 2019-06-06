Feature: Basic Table

Scenario: Tables
Given I have a table
  |Payment_details        |Order_Date     |Order_ID     |
  |Office Supplies 141296 |"Tue 19 Mar 2019"|"190319-356918"|
And I am a step after the table
When I am a table step "executed"
| column1 | column2 | column3 | column4 |
| Z       | 6       | 5       | 4       |
| Z       | 1       | 2       | 3       |
Then everything works just fine