5.0.0
=====
* Requires Dart SDK 3.10 or later (`sdk: ^3.10.0`)
* Updated dependencies to latest: `intl` ^0.20.2, `sprintf` ^7.0.0, `logging` ^1.3.0, `args` ^2.7.0,
  `ansicolor` ^2.0.3, `collection` ^1.19.0
* Replaced the discontinued `pedantic` with `lints` (recommended set) and cleaned up all analyzer issues
* Fixed `OguretsOpts.steps(folder)`: step definition files are now fully loaded (awaited) before the run starts
* Breaking: some previously untyped public signatures are now typed, e.g. the deprecated `run(List<String> args)`,
  `ResultBuffer.write/writeln(String? message, {String? color})`, `GherkinTable.addRow(List<String> row)`
  and `StepFailure(Object e, String? s)`
* Breaking: the internal model types used in the formatter/status API are now public and renamed:
  `_Feature` -> `GherkinFeature`, `_Scenario` -> `GherkinScenario`, `_Background` -> `GherkinBackground`,
  `_Step` -> `GherkinStep`. Custom `Formatter` implementations need to use the new names.
* Breaking: `LogLevel` values are now lowerCamelCase (`LogLevel.FINE` -> `LogLevel.fine`, etc.)
* Breaking: `IntellijFormatter` constants are now lowerCamelCase (`TEAMCITY_PREFIX` -> `teamcityPrefix`,
  `TEMPLATE_TEST_STARTED` -> `templateTestStarted`, etc.)
* Generated boilerplate for missing steps now uses lowerCamelCase method names, `void` return types
  and typed parameters, so it passes the recommended lints
* The console (non-IntelliJ) output now ends with a "Failed scenarios" section that reprints every failed
  scenario, including its background and example row: passed steps in green, the failed step in red with its
  error and stack trace, skipped steps in gray and undefined steps in yellow. Failing hooks are shown too.
  Use `BasicFormatter(buffer, failureSummary: false)` to turn it off.
* The console output's scenario and feature pass/skip/fail counts are now printed once, as totals for the
  whole run, after the failed scenarios and missing steps (previously scenario counts were printed per feature)
* `RunStatus.passedScenarios` / `skippedScenarios` / `failedScenarios` no longer throw when no features ran
* Breaking: tags from the command line (`run(args: args)` with `--tags`) and from `OGURETS_TAGS` are now
  **added** to the tags configured with `OguretsOpts.tags(...)` instead of replacing them. Pass `--replace-tags`
  or set `OGURETS_REPLACE_TAGS=true` to get the old replacing behaviour. `--tags` can be given more than once
  and also accepts `--tags=<tags>`
* Unknown command line arguments are now ignored instead of throwing a `FormatException`, so `main`'s arguments
  can be shared with other code. The `args` dependency has been removed
* Breaking: a failed run now sets the process `exitCode` to 1 (it does not call `exit()`). Turn this off with
  `OguretsOpts.failOnError(false)`, `--no-fail-on-error` or `OGURETS_FAIL_ON_ERROR=false`
* `@StepDef` should not be used to annotate steps, as it is not a standard Gherkin keyword: use `@Given`,
  `@When`, `@Then`, `@And` or `@But`. The examples now do, and missing-step boilerplate for `*` steps now
  suggests `@Given` instead of `@StepDef`
* Removed the `bin/cucumberd.dart` runner. It only looked in a hard-coded `example/steps` folder and always
  exited with 0; use `OguretsOpts` with `..steps(folder)` instead
* Running `OguretsOpts.run()` several times in one process no longer prints every log line once per run
* The example project's tests now run every example feature and sample and check each passes or fails as
  intended, including the exit codes of the samples
* Fixed the deprecated top-level `run(args)`, which always crashed with a type cast error since null safety
* `ScenarioStatus.executedSteps` lists every step, background step and hook of a scenario in execution order
* Replaced the custom Gherkin parser with the official Cucumber parser,
  [cucumber_gherkin](https://pub.dev/packages/cucumber_gherkin):
  * New: `*` steps, every Gherkin language (`# language: xx`), `Example` / `Scenario Template` keywords,
    several `Examples` blocks per outline, and escaped table cells (`\|`, `\\`, `\n`)
  * Invalid feature files now throw `GherkinSyntaxError` listing every error with its location;
    the old parser silently ignored lines it did not understand
  * `GherkinScenario.gherkinKeyword` is now the keyword used in the file (e.g. `Scenario Outline`)
  * Doc strings have their indentation removed relative to the opening `"""`, as in other Cucumber implementations
  * Step line numbers after a doc string are now correct
  * Placeholders for Gherkin that ogurets cannot run yet: `Rule` (scenarios are flattened into the feature,
    with a warning), a `Background` inside a `Rule` (throws `GherkinUnsupportedError`), tags on `Examples`
    and doc string media types (ignored, with a warning)
  * Breaking: removed the public `GherkinVocabulary` class and the regex top-level variables
    (`tagsPattern`, `featurePattern`, `scenarioPattern`, ...)

4.0.6
=====
* Make sure failed "dependency injection" results in failed steps/scenarios/features

4.0.5
=====
* Added option to filter out certain types of messages that are logged by default (steps, backgrounds, scenario's, features)

4.0.4
=====
* Added option to change log level of ogurets through OguretsOpts

4.0.3
=====
* Skip abstract classes containing step definitions
* When passing abstract ``ScenarioSession`` type as parameter, instantiate a concrete subclass instead

4.0.2
=====
* Automatically replace placeholders in ``Scenario Outline`` table columns with exampleRow values
  in "table" param, instead of requiring users to look up and replace using the "exampleRow" param

4.0.1
=====
* issue with types with new versions of Dart where the methods aren't being picked up

4.0.0
=====
* updated to support null safety
* updated to support factory based constructors by preference when doing "dependency injection"

3.2.1
=====
* Update to allow correct interpolation of scenario name when using data tables; contribution

3.2.0
=====
* this is a rearrangement into a single library and hiding of internal classes so they don't
cause conflict with our work on FeatureHub (and because they aren't neeeded to be seen externally)
* includes failure fix from tobindh 

3.1.10
=====
* support square brackets in errors in IDEA

3.1.9
=======
* load steps from disk instead of having to specify them all
* better reporting
* timings
* all updates from tobindh

3.1.8
=======
* added @ignore syntax (tobindh)
* allowed specification of extra formatters via Opts (tobindh)
* tidied up logging messages (tobindh)
* added support for skipped scenarios in reporting

3.1.7
=======
* opened up the intl version to include 0.16 because Flutter master has changed

3.1.6
=======
* added in beforestep/afterstep annotations
* added moved examples to own directory, turned them into a test.

3.1.5
=======
* logic around tags was causing everything to run even if you specified a scenario name
* too much print logging

3.1.4
=======
* karthi.kk - reported an issue with tags not working as expected. Tags were not triggering
properly on feature level and scenario level as per other cucumber variants. 
* support for ~tags so you can turn off specific tags

3.1.3
=======
* karthi.kk - reported issue with existing dherkin2 table parser
which only allowed single word entries in table.
 
3.1.2
=======
* updated documentation
* updated the IDEA formatter so it outputs examples correctly
* ensure each example line in a scenario outline has a separate scenario status so it doesn't
prevent other examples from running. 

3.1.1
=======
* Introducing ogurets for the first time

1.0.1+1
=======
* Introduced this changelog.

1.0.1
=======
* Upgraded all dependencies.
* Minimal required Dart SDK is now 2.0.0.
* Removed log4dart because it is not dart2 compatible. Replaced it with the logging lib from pub.dart.

1.0.0
=======
* The fork removed all future-code and replaced it with async/await. The reason for that is that it can properly be used in dart2 tests.
