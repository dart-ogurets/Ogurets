/// Rewrites legacy Ogurets step definitions to the standard Cucumber rules.
///
///     dart run ogurets:migrate_steps [--write] [paths...]
///
/// Without `--write` it only reports what it would change.
library;

import 'dart:io';

import 'package:ogurets/legacy_steps.dart';

const _usage = '''
Rewrites Ogurets step definitions from legacy matching (any text is an
anchored regex) to the standard Cucumber rules (text is a Cucumber Expression
unless it starts with ^ or ends with \$).

Usage: dart run ogurets:migrate_steps [--write] [paths...]

  paths    Dart files or directories to scan (default: the current directory)
  --write  Rewrite the files. Without it, only report what would change.
  --help   Show this help.
''';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.write(_usage);
    return;
  }

  final write = args.contains('--write');
  final unknown = args.where((a) => a.startsWith('-') && a != '--write');
  if (unknown.isNotEmpty) {
    stderr.writeln('Unknown option: ${unknown.first}\n');
    stderr.write(_usage);
    exitCode = 64;
    return;
  }

  final paths = args.where((a) => !a.startsWith('-')).toList();
  final files = _dartFiles(paths.isEmpty ? ['.'] : paths);
  final migrator = LegacyStepMigrator();

  var changedSteps = 0;
  var changedFiles = 0;
  var warningCount = 0;

  for (final file in files) {
    final result = migrator.migrateSource(file.readAsStringSync());
    if (!result.changed && result.warnings.isEmpty) continue;

    stdout.writeln(file.path);
    for (final edit in result.edits) {
      final kind = switch (edit.migration.kind) {
        StepMigrationKind.cucumberExpression => 'cucumber expression',
        StepMigrationKind.regularExpression => 'anchored regex',
        StepMigrationKind.unchanged => 'unchanged',
      };
      stdout
        ..writeln('  line ${edit.line} ($kind)')
        ..writeln('    - ${edit.oldLiteral}')
        ..writeln('    + ${edit.newLiteral}');
      for (final note in edit.migration.notes) {
        stdout.writeln('    note: $note');
      }
    }
    for (final warning in result.warnings) {
      stdout.writeln('  warning: $warning');
    }

    changedSteps += result.edits.length;
    warningCount += result.warnings.length;
    if (result.changed) {
      changedFiles++;
      if (write) file.writeAsStringSync(result.source);
    }
  }

  stdout.writeln(
    '\n$changedSteps step(s) in $changedFiles file(s) '
    '${write ? 'rewritten' : 'would be rewritten'}'
    '${warningCount > 0 ? ', $warningCount warning(s)' : ''}.',
  );
  if (!write && changedSteps > 0) {
    stdout.writeln('Run again with --write to apply the changes.');
  }
}

List<File> _dartFiles(List<String> paths) {
  final files = <File>[];
  for (final path in paths) {
    if (FileSystemEntity.isFileSync(path)) {
      files.add(File(path));
    } else if (FileSystemEntity.isDirectorySync(path)) {
      files.addAll(
        Directory(path)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where(
              (f) => !f.uri.pathSegments.any(
                (s) =>
                    (s.startsWith('.') && s != '.' && s != '..') ||
                    s == 'build',
              ),
            ),
      );
    } else {
      stderr.writeln('Not found: $path');
      exitCode = 66;
    }
  }
  return files..sort((a, b) => a.path.compareTo(b.path));
}
