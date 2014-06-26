dherkin
=======

Gherkin parser and runner for dart.
for Behavior Driven Development (BDD).


Usage
-----

Library comes with an executable runner script **cucumberd** in bin/ directory.
Create symbolic link in a directory on your path, like /usr/local/bin:
```
cd /usr/local/bin
ln -s path/to/dherkin/bin/cucumberd .
```

Execute:
```
cucumberd examples/test_feature.feature
```

Note: **cucumberd** will auto-include all step definitions in *steps/* sub-directory.
Ability to add steps source locations via command-line arguments is planned.


Alternatively, you might opt for writing your own script:

   ```dart
   library my_bdd_runner;

   import 'package:dherkin/dherkin.dart';
   import 'my_step_defs.dart'; // import stepdefs, mandatory since no auto-scanning happens

   main(args) {
     run(args);
   }

   // write your StepDefs below
   ```
Invoke the runner : `$ dart my_bdd_runner.dart my_gherkin.feature`



