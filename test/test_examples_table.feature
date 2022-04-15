Feature: Basic Parser

  Scenario Outline: Outline with a parameterized table step
    Given I have a parameterized statement with param "<countParam>"
    Given I have a parameterized table
      | column1 | column2 | column3      | column4 |
      | <col1>  | <col2>  | FixedCol3Val | <col4>  |
    Examples:
      | countParam | col1 | col2 | col3 | col4 |
      | first      | A    | B    | C    | D    |
      | second     | E    | F    | G    | H    |
