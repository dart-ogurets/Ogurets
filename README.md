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

#### Gherkin support

Since 5.0.0, feature files are parsed with the official Cucumber parser,
[cucumber_gherkin](https://pub.dev/packages/cucumber_gherkin), so ogurets accepts exactly the Gherkin
that other Cucumber implementations do, and reports invalid files as a `GherkinSyntaxError` with
the file, line and column of each problem.

Supported:

- `Feature`, `Background`, `Scenario` / `Example`, `Scenario Outline` / `Scenario Template`
- `Examples` tables (several `Examples` blocks on one outline are merged), step data tables and doc strings
- tags on features and scenarios (scenarios inherit the feature's tags)
- `*` steps, comments, and every Gherkin language (`# language: fr`, ...)

Not supported yet:

- `Rule`: scenarios inside a rule run as if they were directly in the feature (they inherit the rule's tags),
  and a warning is logged. A `Background` inside a `Rule` is rejected with a `GherkinUnsupportedError`.
- tags on an `Examples` block are ignored (all rows run), and a warning is logged.
- doc string media types (`` ```json ``) are ignored; the content is passed as a plain string.
- descriptions (free text under a keyword) and `Examples` names are ignored.

#### authors

This is based on the original work of Dherkin2, along with some modifications made to make it 
Dart 2 compatible by others.

The current authors are: 

- _Richard Vowles_, Software Developer (https://www.linkedin.com/in/richard-vowles-72035193/)

## Important Note

ogurets finds your step definitions, hooks and injected instances at runtime using `dart:mirrors`, which is
deprecated as of Dart 3.14. It still works on the Dart VM, which is where `dart test` runs, and ogurets 5.x
continues to use it. A future major version will replace `dart:mirrors` with code generation, which will
require a build step in projects that use ogurets. We use ogurets heavily in our testing at
FeatureHub.IO (https://featurehub.io).

# an overview of ogurets

ogurets carries on from dherkin2 in a number of ways:

- ogurets requires Dart 3.10+ and is entirely async/await aware. Steps and hooks can be ordinary functions or
`async` ones - if they return a `Future`, ogurets waits for it before moving on.
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

- [ogurets-flutter](https://pub.dev/packages/ogurets_flutter) - and extension for Ogurets focused on supporting Flutter.
- [ogurets IntelliJ plugin](https://plugins.jetbrains.com/plugin/12687-ogurets--cucumber-for-dart) - a plugin for IntelliJ 
that extends the Cucumber support in IntelliJ and Android Studio to allow you to easily create steps, run and debug 
your tests, and navigate through test codebase.

### Usage

Ogurets based Cucumber tests are closely modeled on Java style Step-def classes with annotations. There is `@Given`,
`@When`, `@Then`, `@And` and `@But`, all of which aid you in writing your standard Cucumber based set of tests.

As in other Cucumber implementations, the keyword only affects how the step reads: a step annotated with `@Given`
also matches a `When`, `Then`, `And`, `But` or `*` step with the same text.

Don't use `@StepDef`. It is the base class of these annotations, not a Gherkin keyword, so Cucumber tooling (such
as the IntelliJ plugin) doesn't recognise steps annotated with it. Older ogurets and dherkin2 code often used
it - replace it with the keyword that reads best, e.g. `@Given`.

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

import 'package:my_project/scenario_state.dart';

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

Always import your own library files with `package:` imports. A relative import like `'../lib/scenario_state.dart'`
makes Dart load a second copy of the library, so ogurets ends up with two different `ScenarioState` types and
the instance it injects won't be the one you expect.

When run using _Ogurets_, this gives something like this:

```bash
Feature: simple addition feature # test/features/add.feature:1

	Scenario: A simple addition example # test/features/add.feature:3
		I add 4	 # test/features/add.feature:4
		I add 3	 # test/features/add.feature:5
		the total should be 7	 # test/features/add.feature:6
Scenario passed!
Scenario time: 2 ms
-------------------
Feature time: 3 ms

==================
Scenarios passed: 1
Features passed: 1
Run time: 12 ms
```

Any hooks that run are listed between the steps too. The totals at the end are for the whole run. If any scenario fails, a "Failed scenarios" section is printed
just before them, repeating each failed scenario with its passed steps in green, the failed step in red with its
error and stack trace, and skipped steps in gray. When run from IntelliJ, failures are shown in its test tree instead.

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
void main(List<String> args) async {
  var def = new OguretsOpts()
   ..feature("example/gherkin")
   ..debug()
   ..instance(new SharedInstance())
   ..failOnMissingSteps(false)
   ..tags("~@dataload")
   ..step(Backgrounds)
   ..step(SharedInstanceStepdef)
   ..step(SampleSteps);

  // passing args lets the command line add tags, e.g. --tags @smoke
  await def.run(args: args);
}
```` 

Note, you can include the much easier mechanism of just `..steps(folderName)` now and it will include all steps from
that folder into the scan list for hooks and steps (thanks to tobindh).

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

### parallel runs

If you are doing API testing, you can tell Ogurets to run using parallel features, and it is considerably
faster. For your OguretsOpts object, add `..parallelize()`. If you are using IntelliJ IDEA, then use an
environment variable `CUCUMBER_PARALLEL=true`. This option does work in IDEA, but the reporting is pretty
terrible and will take a while to get sorted. 

### ogurets hooks

Hooks work largely like you would expect them to. You can:

- specify a tag or not (in the annotation). If not, then the before or after will run on every scenario triggered.
- specify instances to be injected, including the `ScenarioStatus` that holds details about the current scenario. The
`ScenarioStatus` object holds a map called `addendum` which allows you to put in Scenario related things (such as references
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
  void beforeEach(ScenarioSession session, ScenarioStatus tracker) {
    session.sharedStepData['before-all'] = 'here';
    tracker.addendum['before-all'] = true; // this will be attached to the scenario object that generates the report
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
 
Using the ~@tag syntax prevents the tagged scenario or feature from being run, leaving all others open. When
~@tags and @tags are combined, the ~@tags are applied first, and a scenario that is not excluded runs if it has
*any* of the @tags (scenarios inherit their feature's tags).

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

#### Choosing tags at run time

Tags set with `..tags("...")` can be added to when the tests are run:

* on the command line, with `--tags "<tags>"` (or `--tags=<tags>`). This only works if `main` passes its
  arguments on with `def.run(args: args)`. `--tags` can be repeated, and other arguments are ignored, so
  `main`'s arguments can also be used for other things.
* with the `OGURETS_TAGS` environment variable, e.g. `OGURETS_TAGS="@smoke" dart test`. Use this with
  `dart test`, which does not pass command line arguments to your test.

Command line and environment tags are **added** to the configured tags. To use only the command line /
environment tags instead, pass `--replace-tags` or set `OGURETS_REPLACE_TAGS=true`. For example, with
`..tags("~@slow")` configured:

* `--tags @smoke` runs `@smoke` scenarios that are not `@slow`
* `--replace-tags --tags @slow` runs only the `@slow` scenarios

`--debug` turns on debug logging.

#### Exit code

If any feature fails (including scenarios with missing steps, unless `..failOnMissingSteps(false)`), `run()`
sets the process `exitCode` to 1, so CI and scripts see the failure. It only sets `exitCode` and never calls
`exit()`, so `AfterRun` hooks and code after `run()` still run, and the `RunStatus` is still returned.

To keep the exit code at 0 for a failed run, use `..failOnError(false)`, pass `--no-fail-on-error` or set
`OGURETS_FAIL_ON_ERROR=false`. Do this when calling `run()` from inside `dart test` on features that are
*meant* to fail, as `exitCode` belongs to the whole test process.

#### Samples:

* running with the command line: `--tags @dataload` would run all features here, 
* running with `--tags @superuserload` would run the scenario, ignoring the tag on the feature.
* running with `--tags ~@superuserload` would run the scenarios in the feature but it would not run the `@superuserload`
tagged scenario.
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

#### Deprecated top-level `run`

The top-level `run(args)` function from dherkin2 still exists, but is deprecated. It takes the feature files
as arguments, and finds step definitions that are **top-level functions** in any library your script imports
(step classes, hooks and injected instances are not supported):

````dart
import 'package:ogurets/ogurets.dart';
import 'my_step_defs.dart'; // steps must be imported, nothing is scanned

void main(List<String> args) {
  // ignore: deprecated_member_use
  run(args);
}
````

Invoke the runner: `dart --enable-asserts my_bdd_runner.dart my_gherkin.feature`

Unlike `OguretsOpts`, it does **not** fail scenarios that have missing steps; they are reported as passed. Use
`OguretsOpts` instead.

### Anatomy of a stepdef

A stepdef is a method in a step class (see above) or a top-level function, annotated with one of the Gherkin
keywords. It takes one positional parameter for each value captured from the step text, and can also take up
to three optional named parameters:

````dart
@And("I am a table step {string}")
void iAmATable(String arg1, {Map? exampleRow, GherkinTable? table, StringBuffer? out}) {
  out!.writeln("Executing...${exampleRow!['column2']}");
}
````
Table found on the step will be passed in as **table**.
A scenario outline row will be passed in as **exampleRow**

### Output

Each step keeps its own output, and it is only shown if that step fails. That way a failure comes with the
messages that explain it, and passing steps keep the console quiet. A step's output is:

- anything written to the optional named parameter **out** (a `StringBuffer`), if the step takes it
- anything it `print`s
- anything it logs with [package:logging](https://pub.dev/packages/logging), from any logger and any class.
  The level set on the logger still applies: `Logger.root.level` is `INFO` unless `..debug()` or `--debug` is used.

Output is captured even after an `await` and from code the step calls, because each step runs in its own
`Zone`, which also keeps parallel runs apart. Output from before/after step hooks belongs to the step they ran
around. Before/after scenario hooks have their own output, shown if the hook fails.

````dart
final _log = Logger('payments');

@When("I pay {int} dollars")
Future<void> iPay(int amount, {StringBuffer? out}) async {
  out!.writeln("paying $amount");
  final response = await api.pay(amount);
  _log.info("response: ${response.body}"); // shown only if this step fails
  assert(response.statusCode == 200);
}
````

When a step fails, its output is printed below it, and again in the "Failed scenarios" summary at the end of
the run. In IntelliJ it appears in the failed step's output.

To show every step's output as it happens instead, as earlier versions of ogurets did, set the
`ALWAYS_SHOW_OUT` environment variable (e.g. `ALWAYS_SHOW_OUT=true`). Output is then not captured at all.

Logs from the `ogurets` logger itself are never captured. Log listeners you add yourself to `Logger.root` still
receive every record as it happens.
