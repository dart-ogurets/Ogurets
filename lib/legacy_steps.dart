/// Rewrites step definitions written for Ogurets' legacy step matching into
/// the standard Cucumber rules.
///
/// Up to Ogurets 5.0, any step text that did not start with `^` was treated
/// as an implicitly anchored regular expression, with `{string}`, `{int}` and
/// `{float}` substituted. Ogurets now follows the standard Cucumber rule: text
/// is a regular expression only if it starts with `^` or ends with `$`, and
/// anything else is a Cucumber Expression.
///
/// [LegacyStepMigrator] converts legacy step text to a Cucumber Expression
/// where it can do so safely, and otherwise to an explicitly anchored regular
/// expression that keeps the legacy behaviour exactly.
///
/// From the command line: `dart run ogurets:migrate_steps [--write] [paths]`.
library;

import 'package:cucumber_expressions/cucumber_expressions.dart';

/// What [LegacyStepMigrator.migrateStep] did with a piece of step text.
enum StepMigrationKind {
  /// Already means the same thing under the standard rules.
  unchanged,

  /// Rewritten as a Cucumber Expression.
  cucumberExpression,

  /// Rewritten as an explicitly anchored regular expression.
  regularExpression,
}

/// The result of migrating one piece of step text.
class StepMigration {
  /// The legacy step text.
  final String original;

  /// The step text to use with the standard rules.
  final String migrated;

  final StepMigrationKind kind;

  /// Behaviour differences worth checking in the step's method, e.g. a
  /// parameter that used to arrive as an `int` and is now a `String`.
  final List<String> notes;

  const StepMigration(
    this.original,
    this.migrated,
    this.kind, [
    this.notes = const [],
  ]);

  bool get changed => migrated != original;

  @override
  String toString() => changed ? '$original -> $migrated' : original;
}

/// One step annotation rewritten by [LegacyStepMigrator.migrateSource].
class StepEdit {
  /// 1-based line of the annotation in the original source.
  final int line;

  /// The string literal as it was written in the source.
  final String oldLiteral;

  /// The string literal that replaces it.
  final String newLiteral;

  final StepMigration migration;

  const StepEdit(this.line, this.oldLiteral, this.newLiteral, this.migration);
}

/// A step annotation [LegacyStepMigrator.migrateSource] could not handle.
class StepWarning {
  /// 1-based line of the annotation.
  final int line;
  final String message;

  const StepWarning(this.line, this.message);

  @override
  String toString() => 'line $line: $message';
}

/// The result of migrating a Dart source file.
class SourceMigration {
  /// The rewritten source.
  final String source;
  final List<StepEdit> edits;
  final List<StepWarning> warnings;

  const SourceMigration(this.source, this.edits, this.warnings);

  bool get changed => edits.isNotEmpty;
}

/// Converts legacy Ogurets step text to the standard Cucumber rules.
class LegacyStepMigrator {
  final ExpressionFactory _expressionFactory = ExpressionFactory(
    ParameterTypeRegistry(),
  );

  static const _legacyPlaceholders = {
    '{string}': r'"([^"]*)"',
    '{int}': r'([-+]?\d+)',
    '{float}': r'([-+]?[0-9]*\.?[0-9]+)',
  };

  static const _floatNote =
      '{float} values are now always a double (legacy passed whole numbers as int)';
  static const _stringNote =
      '{string} values are now always a String and may also be single-quoted '
      '(legacy converted numeric text to int/num)';
  static const _wordNote =
      '{word} values are now always a String (legacy converted numeric text to int/num)';
  static const _anonymousNote =
      '{} values are now always a String (legacy converted numeric text to int/num)';

  /// Regex fragments (as written in legacy step text) that have a Cucumber
  /// Expression equivalent, in the order they are tried.
  static final List<(RegExp, String, String?)> _groupConversions = [
    // quoted strings: "(\w+?)", "([^"]*)", "(.*)", '(\w+)', ...
    (
      RegExp(r'"\((?:\\w[+*]\??|\[\^"\][+*]\??|\.[+*]\??)\)"'),
      '{string}',
      _stringNote,
    ),
    (
      RegExp(r"'\((?:\\w[+*]\??|\[\^'\][+*]\??|\.[+*]\??)\)'"),
      '{string}',
      _stringNote,
    ),
    // integers: (\d+), (-?\d+), ([-+]?\d+)
    (RegExp(r'\((?:-\?|\[-\+\]\?|\[\+-\]\?)?\\d\+\)'), '{int}', null),
    // floats, including the legacy {float} expansion
    (
      RegExp(
        r'\((?:-\?|\[-\+\]\?|\[\+-\]\?)?(?:\[0-9\]|\\d)\*\\\.\??(?:\[0-9\]|\\d)\+\)',
      ),
      '{float}',
      _floatNote,
    ),
    // words: (\w+), (\S+), ([^\s]+)
    (RegExp(r'\((?:\\w\+|\\S\+|\[\^\\s\]\+)\)'), '{word}', _wordNote),
    // anything: (.*), (.+)
    (RegExp(r'\(\.[+*]\??\)'), '{}', _anonymousNote),
  ];

  /// `(?:text)?` - optional text in a Cucumber Expression.
  static final RegExp _optionalText = RegExp(
    r'\(\?:([^\\()\[\]{}|?*+^$]+)\)\?',
  );

  static const _regexMetaChars = r'\()[]{}|?*+^$';
  static const _regexEscapable = r'\.()[]{}|?*+^$/-';

  /// Migrates a single piece of legacy step text.
  StepMigration migrateStep(String text) {
    final hasPlaceholders = _legacyPlaceholders.keys.any(text.contains);

    if (text.startsWith('^') || text.endsWith(r'$')) {
      // Legacy left `^...` regexes alone unless they used placeholders, and
      // anchored everything else.
      if (text.startsWith('^') && !hasPlaceholders) {
        return StepMigration(text, text, StepMigrationKind.unchanged);
      }
      return _toLegacyRegex(text);
    }

    return _toCucumberExpression(text) ?? _toLegacyRegex(text);
  }

  /// The regex legacy Ogurets would have built from [text], anchored so the
  /// standard rules treat it as a regex too.
  StepMigration _toLegacyRegex(String text) {
    var pattern = text;
    _legacyPlaceholders.forEach((k, v) => pattern = pattern.replaceAll(k, v));
    if (!pattern.startsWith('^')) pattern = '^$pattern';
    if (!pattern.endsWith(r'$')) pattern = '$pattern\$';

    // check the regex is valid; if not, legacy was broken too, so leave it
    try {
      RegExp(pattern);
    } on FormatException {
      return StepMigration(text, text, StepMigrationKind.unchanged, [
        'not a valid regular expression, left as is',
      ]);
    }

    return StepMigration(
      text,
      pattern,
      pattern == text
          ? StepMigrationKind.unchanged
          : StepMigrationKind.regularExpression,
    );
  }

  /// Converts legacy (regex) step text to an equivalent Cucumber Expression,
  /// or returns null if that can't be done safely.
  StepMigration? _toCucumberExpression(String text) {
    final out = StringBuffer();
    final notes = <String>{};
    var pos = 0;

    // the last thing written was a single literal letter, for `steps?`
    String? lastLiteral;

    while (pos < text.length) {
      final rest = pos;

      // legacy placeholders stay as they are
      final placeholder = _legacyPlaceholders.keys.firstWhere(
        (p) => text.startsWith(p, rest),
        orElse: () => '',
      );
      if (placeholder.isNotEmpty) {
        out.write(placeholder);
        if (placeholder == '{float}') notes.add(_floatNote);
        if (placeholder == '{string}') notes.add(_stringNote);
        pos += placeholder.length;
        lastLiteral = null;
        continue;
      }

      final conversion = _groupConversions
          .map((c) => (c.$1.matchAsPrefix(text, rest), c.$2, c.$3))
          .firstWhere((c) => c.$1 != null, orElse: () => (null, '', null));
      if (conversion.$1 != null) {
        out.write(conversion.$2);
        if (conversion.$3 != null) notes.add(conversion.$3!);
        pos = conversion.$1!.end;
        lastLiteral = null;
        continue;
      }

      final optional = _optionalText.matchAsPrefix(text, pos);
      if (optional != null) {
        out.write('(${_escapeCucumber(optional.group(1)!)})');
        pos = optional.end;
        lastLiteral = null;
        continue;
      }

      final char = text[pos];

      if (char == r'\') {
        if (pos + 1 < text.length && _regexEscapable.contains(text[pos + 1])) {
          lastLiteral = text[pos + 1];
          out.write(_escapeCucumber(lastLiteral));
          pos += 2;
          continue;
        }
        return null; // \d, \s, \w etc. outside a group we understand
      }

      // `s?` after a letter: optional single character
      if (char == '?' &&
          lastLiteral != null &&
          RegExp(r'^\w$').hasMatch(lastLiteral)) {
        final soFar = out.toString();
        out
          ..clear()
          ..write(soFar.substring(0, soFar.length - lastLiteral.length))
          ..write('($lastLiteral)');
        pos++;
        lastLiteral = null;
        continue;
      }

      if (_regexMetaChars.contains(char)) {
        return null; // groups, alternation, classes, quantifiers...
      }

      // `.` matched any character in legacy, but is almost always meant as a
      // full stop; as a Cucumber Expression it only matches a full stop.
      out.write(_escapeCucumber(char));
      lastLiteral = char;
      pos++;
    }

    final migrated = out.toString();
    try {
      _expressionFactory.createExpression(migrated);
    } on CucumberExpressionException {
      return null;
    }

    return StepMigration(
      text,
      migrated,
      migrated == text
          ? StepMigrationKind.unchanged
          : StepMigrationKind.cucumberExpression,
      migrated == text ? const [] : notes.toList(),
    );
  }

  /// Escapes the characters that are special in a Cucumber Expression.
  static String _escapeCucumber(String s) =>
      s.replaceAllMapped(RegExp(r'[\\(){}/]'), (m) => '\\${m[0]}');

  // ---------------------------------------------------------------------------
  // Dart source rewriting

  static final RegExp _annotation = RegExp(
    r'@(?:\w+\.)?(?:Given|When|Then|And|But|StepDef)\s*\(\s*',
  );

  /// Rewrites the text of every `@Given`/`@When`/`@Then`/`@And`/`@But` step
  /// annotation in a Dart source file.
  ///
  /// Annotations whose text isn't a single plain string literal (e.g. adjacent
  /// strings or interpolation) are reported in [SourceMigration.warnings] and
  /// left alone. Annotations in `//` comments are skipped.
  SourceMigration migrateSource(String source) {
    final out = StringBuffer();
    final edits = <StepEdit>[];
    final warnings = <StepWarning>[];
    var copiedTo = 0;

    for (final match in _annotation.allMatches(source)) {
      final lineStart = source.lastIndexOf('\n', match.start) + 1;
      if (source.substring(lineStart, match.start).contains('//')) continue;

      final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
      final literal = _DartString.parse(source, match.end);

      if (literal == null) {
        warnings.add(
          StepWarning(line, 'step text is not a plain string literal, skipped'),
        );
        continue;
      }
      if (literal.error != null) {
        warnings.add(StepWarning(line, '${literal.error}, skipped'));
        continue;
      }

      final next = source.substring(literal.end).trimLeft();
      if (!next.startsWith(')') && !next.startsWith(',')) {
        warnings.add(
          StepWarning(line, 'step text is built from several strings, skipped'),
        );
        continue;
      }

      final migration = migrateStep(literal.value);
      for (final note in migration.notes) {
        if (!migration.changed) warnings.add(StepWarning(line, note));
      }
      if (!migration.changed) continue;

      final oldLiteral = source.substring(match.end, literal.end);
      final newLiteral = _DartString.encode(migration.migrated, literal.quote);

      out
        ..write(source.substring(copiedTo, match.end))
        ..write(newLiteral);
      copiedTo = literal.end;
      edits.add(StepEdit(line, oldLiteral, newLiteral, migration));
    }

    out.write(source.substring(copiedTo));
    return SourceMigration(out.toString(), edits, warnings);
  }
}

/// Just enough of a Dart string literal parser for step annotations.
class _DartString {
  final String value;
  final String quote;
  final int end;
  final String? error;

  _DartString(this.value, this.quote, this.end, [this.error]);

  static final RegExp _hex = RegExp(r'^[0-9a-fA-F]+$');

  /// Parses the literal starting at [start], or returns null if there isn't
  /// one there.
  static _DartString? parse(String source, int start) {
    var pos = start;
    final raw = pos < source.length && source[pos] == 'r';
    if (raw) pos++;
    if (pos >= source.length || (source[pos] != '"' && source[pos] != "'")) {
      return null;
    }
    final quote = source[pos];
    if (source.startsWith(quote * 3, pos)) {
      return _DartString(
        '',
        quote,
        pos,
        'multi-line strings are not supported',
      );
    }
    pos++;

    final value = StringBuffer();
    while (pos < source.length) {
      final c = source[pos];
      if (c == quote) {
        return _DartString(value.toString(), quote, pos + 1);
      }
      if (c == '\n') break;
      if (!raw && c == r'$') {
        return _DartString(
          '',
          quote,
          pos,
          'string interpolation is not supported',
        );
      }
      if (!raw && c == r'\' && pos + 1 < source.length) {
        final e = source[pos + 1];
        pos += 2;
        switch (e) {
          case 'n':
            value.write('\n');
          case 'r':
            value.write('\r');
          case 't':
            value.write('\t');
          case 'b':
            value.write('\b');
          case 'f':
            value.write('\f');
          case 'v':
            value.write('\v');
          case 'x' || 'u':
            var digits = '';
            if (e == 'u' && source.startsWith('{', pos)) {
              final close = source.indexOf('}', pos);
              if (close < 0) break;
              digits = source.substring(pos + 1, close);
              pos = close + 1;
            } else {
              final length = e == 'x' ? 2 : 4;
              if (pos + length > source.length) break;
              digits = source.substring(pos, pos + length);
              pos += length;
            }
            if (!_hex.hasMatch(digits)) {
              return _DartString('', quote, pos, 'invalid escape in string');
            }
            value.writeCharCode(int.parse(digits, radix: 16));
          default:
            value.write(e);
        }
        continue;
      }
      value.write(c);
      pos++;
    }
    return _DartString('', quote, pos, 'unterminated string');
  }

  /// Writes [value] as a Dart string literal, preferring a raw string so
  /// regex and Cucumber Expression escapes stay readable.
  static String encode(String value, String preferredQuote) {
    final other = preferredQuote == '"' ? "'" : '"';
    final hasControl = value.contains(RegExp(r'[\x00-\x1f]'));
    if (!hasControl) {
      if (!value.contains(preferredQuote)) {
        return 'r$preferredQuote$value$preferredQuote';
      }
      if (!value.contains(other)) return 'r$other$value$other';
    }
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll(preferredQuote, '\\$preferredQuote')
        .replaceAll(r'$', r'\$')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
    return '$preferredQuote$escaped$preferredQuote';
  }
}
