dherkin
=======

Gherkin parser and runner for dart.
Currently provides basic Cucumber-like functionality
for Behavior Driven Development (BDD).


Usage
-----

1. Create your runner :
  ``` dart my_awesome_bdd.dart
  library my_awesome_bdd;

  import 'package:dherkin/dherkin.dart';

  main(args) {
    run(args);
  }

  // your StepDefs will go there
  ```
2. Write gherkin and invoke the runner on it : `dart my_awesome_bdd.dart my_gherkin.feature`
3. Copy and paste generated step definitions.
4. Implement!


Caveat
------

Currently, there is no way to procedurally import dart sources.
This means that all step def providing files need to be manually imported.  :(