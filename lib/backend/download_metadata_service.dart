import 'package:equran/backend/audio_downloads.dart';
import 'package:equran/backend/companion_storage.dart';
import 'package:equran/backend/companion_storage_models.dart';

class DownloadMetadataService {
  const DownloadMetadataService();

  Future<void> syncFromSummary(AudioDownloadsSummary summary) async {
    final DateTime now = DateTime.now();
    final Set<String> seenIds = <String>{};

    for (final AudioDownloadEntry entry in summary.allDownloads) {
      final String id = _idFor(entry);
      seenIds.add(id);
      await DownloadMetadataDB().put(
        id,
        DownloadMetadataEntry(
          id: id,
          reciterCode: entry.reciterCode,
          type: entry.type.name,
          surah: entry.surah,
          ayah: entry.ayah,
          path: entry.file.path,
          sizeBytes: entry.sizeBytes,
          status: 'available',
          updatedAt: now,
        ),
      );
    }

    for (final dynamic rawKey in DownloadMetadataDB().getKeys().toList()) {
      final String key = rawKey.toString();
      if (!seenIds.contains(key)) {
        final dynamic existing = DownloadMetadataDB().get(key);
        if (existing is DownloadMetadataEntry) {
          await DownloadMetadataDB().put(
            key,
            DownloadMetadataEntry(
              id: existing.id,
              reciterCode: existing.reciterCode,
              type: existing.type,
              surah: existing.surah,
              ayah: existing.ayah,
              path: existing.path,
              sizeBytes: existing.sizeBytes,
              status: 'missing',
              updatedAt: now,
            ),
          );
        }
      }
    }
  }

  String _idFor(AudioDownloadEntry entry) {
    final String ayahPart = entry.ayah == null ? 'all' : '${entry.ayah}';
    return '${entry.reciterCode}:${entry.type.name}:${entry.surah}:$ayahPart';
  }
}
