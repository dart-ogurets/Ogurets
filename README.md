dherkin
=======

Gherkin parser and runner for dart.
Currently provides basic Cucumber-like functionality
for Behavior Driven Development (BDD).


Usage
-----

1. Create your runner `my_awesome_bdd.dart` :

``` dart
library my_bdd_runner;

import 'package:dherkin/dherkin.dart';

main(args) {
  run(args);
}

// write your StepDefs below
```

2. Write gherkin `my_gherkin.feature`
3. Invoke the runner : `$ dart my_bdd_runner.dart my_gherkin.feature`
4. Copy and paste generated step definitions.
5. Implement!


Caveat
------

Currently, there is no way to procedurally import dart sources.
This means that all step def providing files need to be manually imported.  :(