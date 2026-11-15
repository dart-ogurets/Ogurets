import 'package:ogurets/legacy_steps.dart';
import 'package:test/test.dart';

void main() {
  final migrator = LegacyStepMigrator();

  String migrate(String text) => migrator.migrateStep(text).migrated;
  StepMigrationKind kind(String text) => migrator.migrateStep(text).kind;

  group('migrateStep', () {
    test('plain text and legacy placeholders are unchanged', () {
      expect(kind('a passing step'), StepMigrationKind.unchanged);
      expect(
        kind('I have a {string} with {float}'),
        StepMigrationKind.unchanged,
      );
      expect(kind('A {string} with {int}.'), StepMigrationKind.unchanged);
    });

    test('regex groups with a Cucumber equivalent are converted', () {
      expect(migrate(r'everything "(\w+?)"'), 'everything {string}');
      expect(migrate(r'the "([^"]*)" and "(.*)"'), 'the {string} and {string}');
      expect(migrate(r"the '(\w+)' value"), 'the {string} value');
      expect(
        migrate(r'I have (\d+) and (-?\d+) cukes'),
        'I have {int} and {int} cukes',
      );
      expect(migrate(r'it costs ([-+]?[0-9]*\.?[0-9]+)'), 'it costs {float}');
      expect(migrate(r'the (\w+) colour'), 'the {word} colour');
      expect(migrate(r'anything (.*)'), 'anything {}');
    });

    test('optional text is converted', () {
      expect(
        migrate('this scenario(?: outline example)? has ran'),
        'this scenario( outline example) has ran',
      );
      expect(migrate('I have (\\d+) cukes?'), 'I have {int} cuke(s)');
    });

    test('escaped regex characters become literal text', () {
      expect(migrate(r'I see \(1\) item\.'), r'I see \(1\) item.');
      expect(migrate(r'a\?'), 'a?');
    });

    test('text special to Cucumber Expressions is escaped', () {
      expect(migrate('read and/or write'), r'read and\/or write');
      expect(kind('read and/or write'), StepMigrationKind.cucumberExpression);
    });

    test('anything else becomes an anchored regex', () {
      expect(
        migrate('a (default|different) value'),
        r'^a (default|different) value$',
      );
      expect(migrate('I click (OK)'), r'^I click (OK)$');
      expect(
        migrate(r'(\d+) items in \s+ "(.*)"'),
        r'^(\d+) items in \s+ "(.*)"$',
      );
      expect(migrate(r'a [abc]+ {string}'), r'^a [abc]+ "([^"]*)"$');
    });

    test('anchored regexes keep their legacy meaning', () {
      expect(kind(r'^already (\d+) a regex'), StepMigrationKind.unchanged);
      expect(kind(r'^fully anchored$'), StepMigrationKind.unchanged);
      // legacy substituted placeholders even in ^ regexes
      expect(migrate(r'^I add {int}'), r'^I add ([-+]?\d+)$');
      // legacy anchored the start of $-ending text
      expect(migrate(r'ends (\w+)$'), r'^ends (\w+)$');
    });

    test('notes flag parameter type changes', () {
      expect(
        migrator.migrateStep(r'everything "(\w+?)"').notes.single,
        contains('{string}'),
      );
      expect(migrator.migrateStep(r'I have (\d+)').notes, isEmpty);
    });
  });

  group('migrateSource', () {
    test('rewrites step annotations and keeps everything else', () {
      const source = r'''
import 'package:ogurets/ogurets.dart';

class Steps {
  @Given("everything \"(\\w+?)\"")
  void everything(String s) {}

  @When(
    'a (default|different) value',
  )
  void value(String v) {}

  // @Then("commented (\\w+) out")

  @ogurets.Then(r'I have (\d+) cukes?')
  void cukes(int n) {}

  @And("a passing step")
  void passing() {}
}
''';

      final result = migrator.migrateSource(source);

      expect(result.edits.map((e) => e.line), [4, 7, 14]);
      expect(result.source, contains(r'@Given(r"everything {string}")'));
      expect(result.source, contains("r'^a (default|different) value\$',"));
      expect(result.source, contains('// @Then("commented (\\\\w+) out")'));
      expect(
        result.source,
        contains(r"@ogurets.Then(r'I have {int} cuke(s)')"),
      );
      expect(result.source, contains('@And("a passing step")'));
      expect(result.warnings, isEmpty);
    });

    test('keeps quotes in the step text valid', () {
      final result = migrator.migrateSource(
        '@Given("say \\"(.*)\\" or \'(\\\\w+)\' (now|later)")',
      );
      expect(
        result.source,
        '@Given("^say \\"(.*)\\" or \'(\\\\w+)\' (now|later)\\\$")',
      );
    });

    test('warns about step text it cannot rewrite', () {
      final result = migrator.migrateSource('''
@Given("a " "split (\\\\d+) step")
@Given(prefix + "x")
@Given("an \$interpolated (\\\\d+) step")
''');
      expect(result.changed, isFalse);
      expect(result.warnings.map((w) => w.line), [1, 2, 3]);
    });
  });
}
