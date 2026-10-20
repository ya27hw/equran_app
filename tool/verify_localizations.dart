import 'dart:convert';
import 'dart:io';

void main() {
  final Directory directory = Directory('lib/l10n');
  final List<File> files =
      directory
          .listSync()
          .whereType<File>()
          .where((File file) => file.path.endsWith('.arb'))
          .toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    stderr.writeln('No ARB files found.');
    exitCode = 1;
    return;
  }

  Set<String> keys(File file) {
    final Object? decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      throw FormatException('${file.path} is not a JSON object.');
    }
    return decoded.keys
        .whereType<String>()
        .where((String key) => !key.startsWith('@'))
        .toSet();
  }

  try {
    final File template = files.firstWhere(
      (File file) => file.path.endsWith('app_en.arb'),
      orElse: () => files.first,
    );
    final Set<String> templateKeys = keys(template);
    final List<String> errors = <String>[];
    for (final File file in files) {
      final Set<String> localeKeys = keys(file);
      final Set<String> missing = templateKeys.difference(localeKeys);
      final Set<String> extra = localeKeys.difference(templateKeys);
      if (missing.isNotEmpty) {
        errors.add('${file.path}: missing ${missing.toList()..sort()}');
      }
      if (extra.isNotEmpty) {
        errors.add('${file.path}: extra ${extra.toList()..sort()}');
      }
    }
    if (errors.isNotEmpty) {
      stderr.writeAll(<String>[...errors, '\n'], '\n');
      exitCode = 1;
      return;
    }
    stdout.writeln(
      'Localization keys are consistent across ${files.length} ARB files.',
    );
  } on Object catch (error) {
    stderr.writeln('Localization verification failed: $error');
    exitCode = 1;
  }
}
