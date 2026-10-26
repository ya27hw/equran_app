import 'dart:io';

/// Hard privacy rules for the app source. Run in CI next to the dependency
/// policy. A failure means a change would send private data off the device.
void main() {
  final List<String> violations = <String>[];

  // Coordinates and addresses never leave the device. Reverse geocoding
  // services and their packages are not allowed.
  final List<String> forbiddenCalls = <String>[
    'package:geocoding/',
    'nominatim',
    'placemarkFromCoordinates',
    'locationFromAddress',
  ];

  // Every outbound host the app may contact. Adding a host needs a review of
  // what it receives. Map tiles are listed because the map picker needs them;
  // they reveal the viewed area, so remove this entry if the map changes.
  final List<String> allowedHosts = <String>[
    'everyayah.com',
    'quranapi.pages.dev',
    'api.metals.live',
    'github.com',
    'f-droid.org',
    'tile.openstreetmap.org',
  ];

  final RegExp hostPattern = RegExp(r'https?://([A-Za-z0-9.-]+)');

  for (final FileSystemEntity entity
      in <Directory>[Directory('lib'), Directory('test')].expand(
        (Directory dir) => dir.existsSync()
            ? dir.listSync(recursive: true)
            : const <FileSystemEntity>[],
      )) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final String path = entity.path.replaceAll('\\', '/');
    final String contents = entity.readAsStringSync();
    // Test fixtures use reserved .invalid hosts; only shipped code is checked.
    final bool shipped = path.startsWith('lib/');

    for (final String call in forbiddenCalls) {
      if (contents.toLowerCase().contains(call.toLowerCase())) {
        violations.add('$path uses "$call", which would send location data');
      }
    }

    for (final RegExpMatch match
        in shipped ? hostPattern.allMatches(contents) : const <RegExpMatch>[]) {
      final String host = match.group(1)!;
      final bool allowed = allowedHosts.any(
        (String allowedHost) =>
            host == allowedHost || host.endsWith('.$allowedHost'),
      );
      if (!allowed) {
        violations.add('$path contacts "$host", which is not an allowed host');
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeAll(<String>[...violations, '\n'], '\n');
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'Privacy policy passed: no location services or unlisted hosts.',
  );
}
