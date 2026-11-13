library;

import 'package:ogurets/ogurets.dart';

class SampleSteps {
  @Given("parser is working")
  void step1({dynamic out}) {
    out.writeln("Компрессия!");
  }

  @But("I run dherkin")
  void iRunDherkin() {}

  @When("everything \"(\\w+?)\"")
  void everythingWorks(dynamic worksArg, StringBuffer out) {
    out.writeln("Everything Works $worksArg");
  }

  @Then("I run some background")
  void iRunSome(dynamic out) {
    out.writeln("I run some background");
  }

  @Then("I have a table")
  void iHaveATable(GherkinTable table) {
    // out.writeln("Table step $table");
  }

  @Then("I am a step after the table")
  void iAmAStepAfter(StringBuffer out) {
    out.writeln("Table2");
  }

  void iAmATableStep({dynamic out}) {
    out.writeln("Table3");
  }

  @Then("everything works just fine")
  void everythingWorksJust(StringBuffer out) {
    out.writeln("Table4");
  }

  @Then("I evaluate {string}")
  void iEvaluateColumn2(String eval, {exampleRow, out}) {
    out.writeln("ROW: $exampleRow");
  }

  @StepDef("I {string} table with example {string}")
  void iEvaluateTableWith(String verb, String col2, {exampleRow, table, out}) {
    out.writeln("Step with table on scenario with example");
    out.writeln("TABLE: $table");
  }

  @And("I am a table step \"(\\w+?)\"")
  void iAmATable(dynamic arg1, {dynamic table}) {}

  @StepDef("the \"(\\w+?)\" of the \"(\\w+?)\" is \"(\\w+?)\"")
  void thePhaseOfThe(dynamic arg1, dynamic arg2, dynamic arg3) {}

  @StepDef("I read {string}")
  void iReadColumn1(String name, {out}) {
    out.writeln("I'm reading a $name");
  }

  @StepDef("I read another {string}")
  void iReadAnotherColumn1(String name, {out}) {
    out.writeln("I'm reading another $name");
  }

  @StepDef("I am a \"(\\w+?)\" step executed")
  void iAmATableStep2(dynamic arg1, {dynamic table, dynamic out}) {
    out.writeln("$arg1 $table");
  }
}
