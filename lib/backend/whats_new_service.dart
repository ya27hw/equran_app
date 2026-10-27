import 'package:equran/backend/settings_db.dart';
import 'package:flutter/material.dart';

class ReleaseHighlight {
  const ReleaseHighlight({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class AppRelease {
  const AppRelease({
    required this.version,
    required this.title,
    required this.highlights,
  });

  final String version;
  final String title;
  final List<ReleaseHighlight> highlights;
}

class WhatsNewService {
  WhatsNewService._();
  static final WhatsNewService instance = WhatsNewService._();

  static const String _keyLastSeenAppVersion = 'lastSeenAppVersion';

  /// History of user-facing release notes written in clear, simple language.
  static const List<AppRelease> releases = <AppRelease>[
    AppRelease(
      version: '4.0.0-beta.5',
      title: 'What’s New in eQuran',
      highlights: <ReleaseHighlight>[
        ReleaseHighlight(
          icon: Icons.text_fields_rounded,
          title: 'Custom Translation Fonts',
          description:
              'Switch between classic Serif and clean modern Sans-Serif fonts to read translation verses comfortably.',
        ),
        ReleaseHighlight(
          icon: Icons.format_bold_rounded,
          title: 'Bold & High Contrast Modes',
          description:
              'Make translation text bold or switch to crisp high contrast for enhanced visibility.',
        ),
        ReleaseHighlight(
          icon: Icons.auto_awesome_rounded,
          title: 'Update Highlights & Notes',
          description:
              'Easily catch up on new additions right when you update, or revisit them anytime from the More menu.',
        ),
        ReleaseHighlight(
          icon: Icons.check_circle_outline_rounded,
          title: 'Simple Bug Fixes',
          description:
              'Minor touch-ups and stability fixes for everyday reading.',
        ),
      ],
    ),
    AppRelease(
      version: '4.0.0-beta.4',
      title: 'What’s New in eQuran',
      highlights: <ReleaseHighlight>[
        ReleaseHighlight(
          icon: Icons.format_size_rounded,
          title: 'Larger, Clearer Translations',
          description:
              'We increased the default translation text size to make every verse effortless and comfortable to read.',
        ),
        ReleaseHighlight(
          icon: Icons.tune_rounded,
          title: 'Wider Text Size Range',
          description:
              'You can now adjust translation text even larger (up to 30 sp) to match your personal reading preference.',
        ),
        ReleaseHighlight(
          icon: Icons.speed_rounded,
          title: 'Instant Text Adjustments',
          description:
              'Moving the text size slider now updates the reading preview immediately as you drag.',
        ),
        ReleaseHighlight(
          icon: Icons.auto_awesome_rounded,
          title: 'Simple Bug Fixes',
          description:
              'Fixed minor issues under the hood to keep your reading smooth and dependable.',
        ),
      ],
    ),
    AppRelease(
      version: '4.0.0-beta.3',
      title: 'Major Redesign & Polish',
      highlights: <ReleaseHighlight>[
        ReleaseHighlight(
          icon: Icons.palette_outlined,
          title: 'Fresh Modern Look',
          description:
              'Enjoy newly redesigned reading themes, AMOLED pure black, and a responsive navigation dock.',
        ),
        ReleaseHighlight(
          icon: Icons.access_time_rounded,
          title: 'Enhanced Prayer Times',
          description:
              'Redesigned prayer schedules, next-prayer indicators, and accurate local calculations.',
        ),
        ReleaseHighlight(
          icon: Icons.build_circle_outlined,
          title: 'Simple Bug Fixes',
          description:
              'Performance and memory improvements for everyday stability.',
        ),
      ],
    ),
  ];

  /// Returns the latest release note highlights.
  AppRelease get latestRelease => releases.first;

  /// Checks whether the post-update popup should be presented to the user.
  ///
  /// - Returns `false` on a fresh install (recording current version quietly).
  /// - Returns `true` if the app was updated to a newer version than previously seen.
  bool shouldShowWhatsNew(String currentVersion) {
    final String? lastSeen =
        SettingsDB().get(_keyLastSeenAppVersion) as String?;

    if (lastSeen == null) {
      // First install: record current version so we don't disrupt initial launch
      markWhatsNewSeen(currentVersion);
      return false;
    }

    return lastSeen != currentVersion;
  }

  /// Marks the given app version as seen so the popup will not show again.
  void markWhatsNewSeen(String currentVersion) {
    SettingsDB().put(_keyLastSeenAppVersion, currentVersion);
  }
}
