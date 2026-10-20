import 'dart:io';

void main() {
  final List<String> paths = <String>['pubspec.yaml', 'pubspec.lock'];
  final List<String> forbidden = <String>[
    'firebase',
    'google_mobile_ads',
    'com.google.android.gms',
    'play-services',
  ];
  final List<String> violations = <String>[];
  for (final String path in paths) {
    final File file = File(path);
    if (!file.existsSync()) {
      violations.add('$path is missing');
      continue;
    }
    final String contents = file.readAsStringSync().toLowerCase();
    for (final String token in forbidden) {
      if (contents.contains(token.toLowerCase())) {
        violations.add('$path contains forbidden dependency token "$token"');
      }
    }
  }
  if (violations.isNotEmpty) {
    stderr.writeAll(<String>[...violations, '\n'], '\n');
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'Dependency policy passed: no GMS/Firebase dependency tokens.',
  );
}
