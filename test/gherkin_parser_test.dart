import 'package:logging/logging.dart';
import 'package:ogurets/ogurets.dart';
import 'package:test/test.dart';

const file = 'test.feature';

Future<GherkinFeature?> parse(String source) => GherkinParserTask(
  Logger('parser-test'),
  source.split('\n'),
  file,
).execute();

void main() {
  final warnings = <String>[];

  setUpAll(() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord
        .where((r) => r.level == Level.WARNING)
        .listen((r) => warnings.add(r.message));
  });

  setUp(warnings.clear);

  test('returns null when there is no feature', () async {
    expect(await parse('# just a comment\n'), isNull);
  });

  test('parses features, backgrounds, scenarios, steps and tags', () async {
    final feature = (await parse('''
@feature
Feature: Basics
  Background:
    Given a background

  @scenario
  Scenario: First
    Given a step
    * a star step
'''))!;

    expect(feature.name, 'Basics');
    expect(feature.tags, ['@feature']);
    expect(feature.location.srcLineNumber, 2);
    expect(feature.background, isA<GherkinBackground>());
    expect(feature.background!.steps.single!.verbiage, 'a background');

    final scenario = feature.scenarios.single!;
    expect(scenario.gherkinKeyword, 'Scenario');
    expect(scenario.tags, ['@feature', '@scenario']);
    expect(scenario.steps.map((s) => s!.verb), ['Given', '*']);
    expect(scenario.steps.last!.location.srcLineNumber, 9);
    expect(
      scenario.steps.last!.boilerplate,
      contains('@StepDef("a star step")'),
    );
  });

  test('doc strings drop indentation and keep a trailing newline', () async {
    final step = (await parse('''
Feature: Doc strings
  Scenario: Indented
    Given some json
      ```json
      {
        "a": 1
      }
      ```
'''))!.scenarios.single!.steps.single!;

    expect(step.pyString, '{\n  "a": 1\n}\n');
    expect(warnings.single, contains("media type 'json' is ignored"));
  });

  test('data tables unescape cells', () async {
    final table = (await parse(r'''
Feature: Tables
  Scenario: Escapes
    Given a table
      | name | value  |
      | pipe | a \| b |
'''))!.scenarios.single!.steps.single!.table;

    expect(table.names, ['name', 'value']);
    expect(table.single, {'name': 'pipe', 'value': 'a | b'});
  });

  test('multiple Examples blocks are merged into one table', () async {
    final scenario = (await parse('''
Feature: Outlines
  Scenario Outline: Merge
    Given <a> and <b>

    Examples: first
      | a | b |
      | 1 | 2 |

    @slow
    Examples: second
      | b | a |
      | 4 | 3 |
'''))!.scenarios.single!;

    expect(scenario.gherkinKeyword, 'Scenario Outline');
    expect(scenario.examples.names, ['a', 'b']);
    expect(scenario.examples.toList(), [
      {'a': '1', 'b': '2'},
      {'b': '4', 'a': '3'},
    ]);
    // placeholder: Examples-level tags are not supported yet
    expect(
      warnings.single,
      contains('tags on \'Examples\' (@slow) are ignored'),
    );
  });

  test(
    'Rule scenarios are flattened into the feature and inherit tags',
    () async {
      final feature = (await parse('''
@feature
Feature: Rules
  @rule
  Rule: A rule
    @scenario
    Example: In a rule
      Given a step
'''))!;

      final scenario = feature.scenarios.single!;
      expect(scenario.name, 'In a rule');
      expect(scenario.tags, ['@feature', '@rule', '@scenario']);
      // placeholder: Rule grouping is not supported yet
      expect(
        warnings.single,
        contains("'Rule: A rule' grouping is not supported"),
      );
    },
  );

  test('a Background inside a Rule is rejected', () async {
    expect(
      parse('''
Feature: Rules
  Rule: A rule
    Background:
      Given rule setup
    Scenario: In a rule
      Given a step
'''),
      throwsA(
        isA<GherkinUnsupportedError>().having(
          (e) => e.message,
          'message',
          contains('$file:3: a Background inside a Rule'),
        ),
      ),
    );
  });

  test('other Gherkin dialects are supported', () async {
    final feature = (await parse('''
# language: fr
Fonctionnalité: Bonjour
  Scénario: Salut
    Soit une étape
'''))!;

    expect(feature.name, 'Bonjour');
    final step = feature.scenarios.single!.steps.single!;
    expect(step.verb, 'Soit');
    expect(step.verbiage, 'une étape');
  });

  test('invalid Gherkin throws a GherkinSyntaxError', () async {
    expect(
      parse('''
Feature: Broken
  Scenario: Bad
    Given a step
    this is not a step
'''),
      throwsA(
        isA<GherkinSyntaxError>().having(
          (e) => e.message,
          'message',
          allOf(startsWith(file), contains('(4:')),
        ),
      ),
    );
  });
}
