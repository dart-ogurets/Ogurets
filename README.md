# ogurets

ogurets is a Gherkin + Cucumber implementation in Dart, focused on making your life writing tests as easy as possible,
with the minimum of boilerplate fuss.

It is a fork of the excellent source base of dherkin2 but as that project appears to be dead and we cannot
release any further versions, it has been renamed to ogurets (огурец) because it sounds cool and it means cucumber. 

For information on Gherkin syntax and Behavior Driven Development (BDD) as a general topic, please 
see: http://cukes.info/

This is one of a few projects that will be released
under this organisational banner - with Flutter and IntelliJ support.

ogurets (like dherkin2) supports standard syntax, scenario outlines with data tables, examples and hooks. It also adds
support for (and preference for) _Cucumber Expressions_.

#### authors

This is based on the original work of Dherkin2, along with some modifications made to make it 
Dart 2 compatible by others.

The current authors are: 

- _Irina Southwell (nee Капрельянц Ирина)_, Principal Engineer (https://www.linkedin.com/in/irina-southwell-9727a422/)
- _Richard Vowles_, Software Developer (https://www.linkedin.com/in/richard-vowles-72035193/)

# an overview of ogurets

ogurets carries on from dherkin2 in a number of ways:

- ogurets is based on Dart 2.2+ and is entirely async/await aware. It expects your functions to be async
functions. 
- offers support for Cucumber expressions of {string}, {int} and {float} instead of having to write regular
expressions.
- supports an Object (OguretsOpts) that defines what features are run, what steps to use and shared instances
- supports steps in classes that have positional instances and shared instances passed to them. This allows you
to have a global variable that stays for the entire run and ones that get recreated for each session (such as a
scenario session). It is a basic form of Dependency Injection. 
- there is an IntelliJ plugin that gives you support for navigation, step creation, run configurations, and displaying
the results of test runs.
- allows overriding of what is actually being run via environment variables (used by the IntelliJ plugin)
- added support for @Before and @After hooks with optional tags
- reports allow flexible reporting style. A basic one and an IntelliJ one are included - and you can chain them
or have multiple of them as you wish.
- fields are extracted out of the example rows so you don't have to.

You can still use your existing Dherkin2 style tests and continue by extending with class based tests.

#### ogurets extensions

- ogurets-flutter
- ogurets IntelliJ plugin

### Usage

Ogurets based Cucumber tests are closely modeled on Java style Step-def classes with annotations. There is `@Given`,
`@When`, `@Then`, `@And` and `@But`, all of which aid you in writing your standard Cucumber based set of tests.

An example of a Cucumber feature in _Ogurets_:

```dart
Feature: simple addition feature

  Scenario: A simple addition example
    Given I add 4
    And I add 3
    Then the total should be 7
```

To ensure this test runs, you will need to create a Stepdef class that implements these steps:

```dart
import 'package:ogurets/ogurets.dart';

class MyStepdefs {
  @Given(r'I add {int}')
  void iAdd(int toadd) async {
    // Write code here that turns the phrase above into concrete actions

  }

  @Then(r'the total should be {int}')
  void theTotalShouldBe(int total) async {
    // Write code here that turns the phrase above into concrete actions

  }
}
```

NOTE: if you are using the IDEA plugin, you can just use Alt-Enter and it will create them for you.

To allow us to use some state which exists only for the scenario, lets go and create ourselves a scenario state class.

```dart
class ScenarioState {
  int total = 0;
}
```
And get _Ogurets_ to create it for each scenario run and pass it to us, the whole stepdef becoming:

```dart
import 'package:ogurets/ogurets.dart';

import '../lib/scenario_state.dart';

class MyStepdefs {
  final ScenarioState state;

  MyStepdefs(this.state);

  @Given(r'I add {int}')
  void iAdd(int toadd) async {
    state.total += toadd;
  }

  @Then(r'the total should be {int}')
  void theTotalShouldBe(int total) async {
    assert(total == state.total);
  }
}
``` 


When run using _Ogurets_, this gives something like this:

```bash
Feature: simple addition feature # test/features/add.feature:1


	Scenario: A simple addition example # test/features/add.feature:3

		I add 4	 # test/features/add.feature:4

		I add 3	 # test/features/add.feature:5

		the total should be 7	 # test/features/add.feature:6

-------------------
Scenarios passed: 1

==================
Features passed: 1
```

You can also use *Scenario Outline* style Gherkin tests to achieve the same effect, but in a table.  

````dart
  Scenario Outline: A simple addition example
    Given I add <amt1>
    And I add <amt2>
    Then the total should be <total>
    Examples:
      | amt1 | amt2 | total |
      | 4    | 3    | 7     |
````

### Run

ogurets can be executed in a number of ways. In all case, you need to ensure the vm-flag `--enable-asserts` is
passed to dart to ensure your assertions throw exceptions. For example:

`dart --enable-asserts test/ogurets_run.dart`

If you do this from IDEA, it automatically adds it for you.

#### ogurets Custom Runner

You create a new `OguretsOpts` and give it your features (individual files or recursed folders) and tell it to run.
You can tell it to not fail on missing steps, turn debug on, provide instances that will live across all tests.

NOTE: if you are using the Ogurets IntelliJ IDEA plugin, this will be automatically generated for you.

````dart
void main(args) async {
  var def = new OguretsOpts()
   ..feature("example/gherkin")
   ..debug()
   ..instance(new SharedInstance())
   ..failOnMissingSteps(false)
   ..tags("~@dataload")
   ..step(Backgrounds)
   ..step(SharedInstanceStepdef)
   ..step(SampleSteps);

  await def.run();
}
````

Your classes can be constructed so as to take classes that are either defined in the `OguretsOpts` or they are
dynamically constructed at runtime. If they themselves depend on a class it will cycle through creating the entire
tree. "Cucumber Expressions" will be turned into regexs as the code is walked through.


e.g.

````dart
class Expressions {
     ScenarioSession _session;
     
     Expressions(this._session);
   
     @Given("I have a {string} with {float}")
     void strFloat(String s, num f) {
       _session.sharedStepData[s] = f;
     }
 ```` 

NOTE: You cannot include anything in the constructor that it does not know about.

### ogurets hooks

Hooks work largely like you would expect them to. You can:

- specify a tag or not (in the annotation). If not, then the before or after will run on every scenario triggered.
- specify instances to be injected, including the `ScenarioStatus` that holds details about the current scenario. The
`ScenarioStatus` object holds a map called 'augments' which allows you to put in Scenario related things (such as references
to screen shots, or json objects or whatever you like) so you will be able to build custom reports that output those
things.

There are several hooks that you can use to make your tests run better:

- `@BeforeRun`/`@AfterRun` - these run before and after the run. They are not tagged but they can have an order. The Ogurets 
Flutter plugin uses them to start and stop the Flutter application.
- `@Before`/`@After` - these run before and after a scenario (regardless of success or failure).
- `@BeforeStep`/`@AfterStep` - these run before and after a step (even on failure). When the AfterStep runs, you are able to
determine if the scenario has failed and if so, you can take action. 


NOTE: no optional parameters are allowed as there is no "context". 

````dart
import 'package:ogurets/ogurets.dart';

import 'scenario_session.dart';

class Hooks {
  @Before()
  void beforeEach(ScenarioSession session) {
    session.sharedStepData['before-all'] = 'here';
  }

  @After()
  void afterEach(ScenarioSession session) {
    session.sharedStepData['after-all'] = 'here';
  }

  @Before(tag: 'CukeExpression')
  void beforeExpression(ScenarioSession session) {
    session.sharedStepData['before-expr'] = 'here';
  }

  @After(tag: 'CukeExpression')
  void afterExpression(ScenarioSession session) {
    session.sharedStepData['after-expr'] = 'here';
  }
}
````

### ogurets tags

Tags also work as per the Cucumber style, where they can be on a feature or on a scenario. If tags are passed they
are specifically honoured, if they aren't then all scenarios will be run.
 
Using the ~@tag syntax prevents the tagged scenario or feature from being run, leaving all others open. Combining
~@tag and @tags leads to non-deterministic behaviour. 

```gherkin
@dataload
Feature: load the sample data via the api

  @superuserload
  Scenario Outline: There should be superusers loaded
    Given the system has been initialized
    And I am logged in as the initialized user
    When I register a new user with email "<email>" and groups "<groups>"
    And complete their registration with name "<name>" and password "<password>" and email "<email>"
    Then the user exists and has superuser groups
    And I can login as user "<email>" with password "<password>"
    Examples:
      | name             | email                  | password    | groups    |
      | Капрельянц Ирина | Ирина@mailinator.com   | password123 | superuser |
      | Irina Southwell  | irina@mailinator.com   | password123 | superuser |
      | Richard Vowles   | richard@mailinator.com | password123 | superuser |
``` 

#### Samples:

* running with the command line: `--tags @dataload` would run all features here, 
* running with `--tags @superuserload` would run the scenario, ignoring the tag on the feature.
* running with `--tags ~@superuserload` would run the scenarios in the feature but it would not run the `@superuserload`
tagged feature.
* running with `--tags ~@dataload` would ignore the whole feature and it wouldn't be otherwise examined for positive
tags.  
 
#### failure

Ogurets relies on simple assertions when doing BDD style testing. Dart provides a rich api for doing comparison, so an
assertion library like Fest Assert is largely unnecessary. 

````dart
  @Given("the total should be {int}")
  void totalShouldBe(int amt) async {
    var calcedVal = (_scenarioSession.sharedStepData["add"] as int);
    assert(amt == calcedVal);
  }
```` 

The more detailed `expect` library provide by the Dart Test library is heavily tied to that library and not usable elsewhere.

#### cucumberd

Library comes with an executable runner script **cucumberd** in bin/ directory.
Create symbolic link in a directory on your path, like /usr/local/bin:

````bash
cd /usr/local/bin
ln -s path/to/ogurets/bin/cucumberd.dart cucumberd
cd
````

Execute:
````bash
cucumberd example/gherkin/test_feature.feature
````

Note: **cucumberd** will auto-include all step definitions in *steps/* sub-directory.
Ability to add steps source locations via command-line arguments is planned.

#### ogurets style Custom Runner

Alternatively, you might opt for writing your own script:

````dart
   library my_bdd_runner;

   import 'package:ogurets/ogurets.dart';
   import 'my_step_defs.dart'; // import stepdefs, mandatory since no auto-scanning happens

   main(args) {
     run(args);
   }

   // write your StepDefs below
````

Invoke the runner : `$ dart my_bdd_runner.dart my_gherkin.feature`

### Anatomy of a stepdef

A stepdef is a top-level function annotated with one of Gherkin keywords.
Such a function can take any number of positional parameters, and up to three optional named parameters.

````dart
@And("I am a table step \"(\\w+?)\"")
i_am_a_table(arg1, {exampleRow, table, out}) {
   out.writeln("Executing...${exampleRow['column2']}");
}
````
Table found on the step will be passed in as **table**.
A scenario outline row will be passed in as **exampleRow**

### Output

Due to asynchronous nature of execution, output of *print* statements will not appear near the gherkin step that ran them.
For that purpose, optional named parameter **out** will be injected if the stepdef function states that it takes it. Please
use the reporters if you wish to override the syntax.



