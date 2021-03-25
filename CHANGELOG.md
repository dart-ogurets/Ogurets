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
