part of '../ogurets.dart';

/// Thrown when a feature file is not valid Gherkin.
///
/// The message contains every error reported by the parser, each prefixed
/// with `file:line:column`.
class GherkinSyntaxError extends StateError {
  GherkinSyntaxError(super.msg);
}

/// Thrown when a feature file uses Gherkin that is valid, but that ogurets
/// cannot yet execute correctly (see [_GherkinParser] for the list).
class GherkinUnsupportedError extends UnsupportedError {
  GherkinUnsupportedError(super.message);
}

/// Parses Gherkin using the official Cucumber parser (`cucumber_gherkin`) and
/// converts the resulting AST into the ogurets model ([GherkinFeature],
/// [GherkinScenario], [GherkinBackground], [GherkinStep], [GherkinTable]).
///
/// Supported: features, backgrounds, scenarios / scenario outlines (and their
/// `Example` / `Scenario Template` synonyms), `Examples` tables (multiple
/// blocks are merged), step data tables, doc strings, tags (feature tags are
/// inherited by scenarios), `*` steps, comments and every Gherkin dialect
/// (`# language: xx`).
///
/// Not yet supported by the ogurets runtime. Each is handled at a clearly
/// marked `UNSUPPORTED` placeholder below:
///  * `Rule` grouping: scenarios run as if they belong to the feature directly,
///    and inherit the rule's tags.
///  * `Background` inside a `Rule`: rejected with [GherkinUnsupportedError],
///    because silently skipping its steps would produce wrong results.
///  * Tags on an `Examples` block: ignored, so every row runs regardless of
///    tag filters.
///  * Doc string media types (e.g. ```` ```json ````): the content is passed
///    as a plain string and the media type is dropped.
///  * Descriptions (free text under a Feature, Rule, Scenario, Background or
///    Examples keyword) and `Examples` names: ignored.
class _GherkinParser {
  final Logger log;
  final String filePath;

  _GherkinParser(this.log, this.filePath);

  /// Returns a fully populated Feature from the Gherkin source in [contents],
  /// or `null` when the source contains no `Feature`.
  ///
  /// Throws [GherkinSyntaxError] if the source is not valid Gherkin.
  GherkinFeature? parse(String contents) {
    var nextId = 0;
    final envelopes = cucumber.generateMessages(
      contents,
      filePath,
      cucumber.GherkinOptions(
        includeSource: false,
        includePickles: false,
        idGenerator: () => '${nextId++}',
      ),
    );

    final errors = [
      for (final envelope in envelopes)
        if (envelope.parseError != null) envelope.parseError!,
    ];
    if (errors.isNotEmpty) {
      // the parser includes the "(line:column)" location in each message
      throw GherkinSyntaxError(
        errors.map((e) => '$filePath: ${e.message}').join('\n'),
      );
    }

    final document = envelopes
        .firstWhereOrNull((e) => e.gherkinDocument != null)
        ?.gherkinDocument;
    final feature = document?.feature;
    if (feature == null) {
      return null;
    }

    return _feature(feature);
  }

  GherkinFeature _feature(messages.Feature source) {
    log.fine("Adding feature: ${source.name}");
    final feature = GherkinFeature(source.name, _location(source.location))
      ..tags = _tags(source.tags);
    // TODO: feature descriptions (source.description) are not kept by ogurets.

    for (final child in source.children) {
      if (child.background != null) {
        feature.background = _background(child.background!);
      } else if (child.scenario != null) {
        feature.scenarios.add(_scenario(child.scenario!, feature.tags!));
      } else if (child.rule != null) {
        feature.scenarios.addAll(_rule(child.rule!, feature.tags!));
      }
    }

    return feature;
  }

  /// UNSUPPORTED: ogurets has no concept of a `Rule`. Its scenarios are added
  /// directly to the feature, and inherit the rule's tags (after the feature's).
  List<GherkinScenario> _rule(messages.Rule rule, List<String?> featureTags) {
    _unsupported(
      rule.location,
      "'${rule.keyword}: ${rule.name}' grouping is not supported yet; its "
      "scenarios will run as if they belong to the feature directly",
    );

    final ruleTags = [...featureTags, ..._tags(rule.tags)];
    final scenarios = <GherkinScenario>[];

    for (final child in rule.children) {
      if (child.background != null) {
        // UNSUPPORTED: running the rule background would require ogurets to
        // chain it after the feature background, for this rule's scenarios only.
        throw GherkinUnsupportedError(
          "$filePath:${child.background!.location.line}: a Background inside "
          "a Rule is not supported by ogurets yet",
        );
      } else if (child.scenario != null) {
        scenarios.add(_scenario(child.scenario!, ruleTags));
      }
    }

    return scenarios;
  }

  GherkinBackground _background(messages.Background source) {
    log.fine("Adding background: ${source.name}");
    final background = GherkinBackground(
      source.name,
      _location(source.location),
    )..gherkinKeyword = source.keyword;
    // TODO: background descriptions (source.description) are not kept by ogurets.
    _addSteps(background, source.steps);
    return background;
  }

  GherkinScenario _scenario(
    messages.Scenario source,
    List<String?> inheritedTags,
  ) {
    log.fine("Adding scenario: ${source.name}");
    final scenario = GherkinScenario(source.name, _location(source.location))
      ..gherkinKeyword = source.keyword
      // inherited (feature/rule) tags come first, so scenario tags can override them
      ..tags = [...inheritedTags, ..._tags(source.tags)];
    // TODO: scenario descriptions (source.description) are not kept by ogurets.

    _addSteps(scenario, source.steps);

    for (final examples in source.examples) {
      _addExamples(scenario.examples, examples);
    }

    return scenario;
  }

  void _addSteps(GherkinScenario scenario, List<messages.Step> steps) {
    for (final source in steps) {
      final step = GherkinStep(
        source.keyword.trim(),
        source.text,
        _location(source.location),
        scenario,
      );

      final docString = source.docString;
      if (docString != null) {
        if (docString.mediaType != null && docString.mediaType!.isNotEmpty) {
          _unsupported(
            docString.location,
            "doc string media type '${docString.mediaType}' is ignored",
          );
        }
        // ogurets has always passed doc strings with a trailing newline
        step.pyString = docString.content.isEmpty
            ? ''
            : '${docString.content}\n';
      }

      final dataTable = source.dataTable;
      if (dataTable != null) {
        for (final row in dataTable.rows) {
          step.table.addRow(_cells(row));
        }
      }

      scenario.addStep(step);
    }
  }

  /// Merges an `Examples` block into the scenario's single examples table.
  /// When there are several blocks, each row is keyed by its own block's header.
  void _addExamples(GherkinTable table, messages.Examples examples) {
    final header = examples.tableHeader;
    if (header == null) {
      return; // an `Examples:` keyword without a table has no rows to run
    }

    if (examples.tags.isNotEmpty) {
      _unsupported(
        examples.location,
        "tags on '${examples.keyword}' (${_tags(examples.tags).join(' ')}) are "
        "ignored; all of its rows will run",
      );
    }
    // TODO: examples names and descriptions are not kept by ogurets.

    table._addRows(_cells(header), examples.tableBody.map(_cells));
  }

  List<String> _cells(messages.TableRow row) => [
    for (final cell in row.cells) cell.value,
  ];

  List<String?> _tags(List<messages.Tag> tags) => [
    for (final tag in tags) tag.name,
  ];

  Location _location(messages.Location location) =>
      Location(filePath, location.line);

  void _unsupported(messages.Location location, String message) {
    log.warning("$filePath:${location.line}: $message");
  }
}
