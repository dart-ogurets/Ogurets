library dherkin_stepdefs_py_strings;

import 'package:ogurets/ogurets.dart';

/// PYSTRINGS ------------------------------------------------------------------

String actualPyString;
String expectedPyString = """
line 1
line 2
""";

@StepDef("I have the following PyString:")
i_have_the_following_pystring(pyString) {
  actualPyString = pyString;
}

@StepDef("the above Step should have the PyString as last parameter.")
the_above_stepdef_should_have_the_pystring() {
  // maybe we could use the `matchers` package ? Assertions make sense here.
  // also, dherkin could recognize crash errors from assertions errors using core's AssertionError
  if (actualPyString != expectedPyString) {
    throw new Exception(
        "PyString was not as expected :\n"+
        "[actual]\n$actualPyString\n[expected]\n$expectedPyString");
  }
}

