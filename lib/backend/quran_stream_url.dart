import 'package:equran/backend/library.dart' show SettingsDB;
import 'package:equran/utils/reciter.dart';

class QuranAudioStreamResolver {
  static const String _everyAyahBase = 'https://everyayah.com/data';

  /// Generates individual ayah strings for the reading pages (EveryAyah Model)
  /// Outputs format pattern: https://everyayah.com/data/Alafasy_128kbps/018010.mp3
  static String buildAyahUrl({
    required ReciterProfile reciter,
    required int surah,
    required int ayah,
  }) {
    final String paddedSurah = surah.toString().padLeft(3, '0');
    final String paddedAyah = ayah.toString().padLeft(3, '0');
    return '$_everyAyahBase/${reciter.everyAyahFolder}/$paddedSurah$paddedAyah.mp3';
  }
}

class QuranAudioService {
  AppReciter get selectedReciter {
    final Object? savedValue = SettingsDB().get(
      'reciter',
      defaultValue: 'alafasy',
    );
    final String savedCode = savedValue?.toString() ?? 'alafasy';
    final String normalizedCode = AppReciter.normalizeCode(savedCode);
    if (normalizedCode != savedCode) {
      SettingsDB().put('reciter', normalizedCode);
    }
    return AppReciter.fromCode(normalizedCode);
  }

  Future<String> getAyahUrl(int surah, int ayah) async {
    final reciter = selectedReciter;
    final profile = QuranAudioCatalog.findById(reciter.code);
    return QuranAudioStreamResolver.buildAyahUrl(
      reciter: profile,
      surah: surah,
      ayah: ayah,
    );
  }
}
