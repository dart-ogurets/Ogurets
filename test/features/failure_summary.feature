Feature: Failure summary

  Background:
    Given a passing step

  Scenario Outline: Fails part way through
    Given a passing step with "<value>"
    When this step fails with an exception
    Then a passing step
    And this step has no definition

    Examples:
      | value |
      | one   |

  # The @Before(tag: 'FailedSetup') hook throws, so every scenario step is skipped
  @FailedSetup
  Scenario: Fails in a hook
    Given a passing step
