library;

import 'package:ogurets/ogurets.dart';

/// PYSTRINGS ------------------------------------------------------------------

String? actualPyString;
String expectedPyString = """
line 1
line 2
""";

@Given("I have the following PyString:")
void iHaveTheFollowingPystring(dynamic pyString) {
  actualPyString = pyString;
}

@Given("the above Step should have the PyString as last parameter.")
void theAboveStepdefShouldHaveThePystring() {
  // maybe we could use the `matchers` package ? Assertions make sense here.
  // also, dherkin could recognize crash errors from assertions errors using core's AssertionError
  if (actualPyString != expectedPyString) {
    throw Exception(
      "PyString was not as expected :\n"
      "[actual]\n$actualPyString\n[expected]\n$expectedPyString",
    );
  }
}
