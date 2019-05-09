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

- _Irina Southwell nee Kaprelyants_, Principal Engineer (https://www.linkedin.com/in/irina-southwell-9727a422/)
- _Richard Vowles_, Software Developer (https://www.linkedin.com/in/richard-vowles-72035193/)

# an overview of ogurets

ogurets carries on from dherkin2 in a number of ways:

- ogurets is based on based on Dart 2.2+ and is entirely async/await aware. It expects your functions to be async
functions. 
- offers support for Cucumber expressions of {string}, {int} and {float} instead of having to write regular
expressions.
- supports an Object (DherkinOpts) that defines what features are run, what steps to use and shared instances
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

ogurets can be executed in a number of ways.

ogurets Custom Runner

You create a new `OguretsOpts` and give it your features (individual files or recursed folders) and tell it to run.
You can tell it to not fail on missing steps, turn debug on, provide instances that will live across all tests.

````dart
void main(args) async {
  var def = new OguretsOpts()
   ..feature("example/gherkin")
   ..debug()
   ..instance(new SharedInstance())
   ..failOnMissingSteps(false)
   ..step(Backgrounds)
   ..step(SharedInstanceStepdef)
   ..step(SampleSteps);

  await def.run();
}
````

Your classes can be constructed so as to take classes that are either defined in the `DherkinOpts` or they are
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

- specify a tag or not. If not, then the before or after will run on every scenario triggered.
- specify instances to be injected, including the `OguretsScenarioSession` that holds details about the current scenario.


NOTE: no optional parameters are allowed as there is no "context". 

````dart
import 'package:ogurets/dherkin.dart';

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
 

#### cucumberd

Library comes with an executable runner script **cucumberd** in bin/ directory.
Create symbolic link in a directory on your path, like /usr/local/bin:

````bash
cd /usr/local/bin
ln -s path/to/dherkin/bin/cucumberd.dart cucumberd
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

   import 'package:dherkin/dherkin.dart';
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



