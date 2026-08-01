import 'dart:typed_data';

class QcfCpalPatcher {
  /// Parses the TTF binary, locates the CPAL table, and swaps Palette 0 with Palette 1.
  /// If the table is not found, or there are not enough palettes, or any out-of-bounds
  /// error occurs, this fails silently and returns the original [fontBytes].
  ///
  /// This modifies the [fontBytes] in-place to minimize memory allocation.
  /// Ensure you pass a mutable [Uint8List] (e.g., from `File.readAsBytes()`).
  static Uint8List patchForDarkMode(Uint8List fontBytes) {
    try {
      final ByteData data = ByteData.view(
        fontBytes.buffer,
        fontBytes.offsetInBytes,
        fontBytes.lengthInBytes,
      );

      // 1. TTF Header
      // Check minimum length for TTF header (12 bytes)
      if (data.lengthInBytes < 12) {
        return fontBytes;
      }

      // Read numTables (uint16) at byte offset 4
      final int numTables = data.getUint16(4, Endian.big);

      // 2. Table Directory
      // Starts at byte offset 12. Each record is 16 bytes.
      int cpalOffset = -1;
      int currentOffset = 12;

      for (int i = 0; i < numTables; i++) {
        if (currentOffset + 16 > data.lengthInBytes) {
          return fontBytes; // Out of bounds
        }

        // Read the 4-byte Tag. 'CPAL' is 0x4350414C.
        final int tag = data.getUint32(currentOffset, Endian.big);
        if (tag == 0x4350414C) {
          // Found CPAL. Read offset (uint32) at record + 8.
          cpalOffset = data.getUint32(currentOffset + 8, Endian.big);
          break;
        }

        currentOffset += 16;
      }

      if (cpalOffset < 0 || !_fits(cpalOffset, 16, data.lengthInBytes)) {
        // CPAL table not found or offset out of bounds
        return fontBytes;
      }

      // 3. CPAL Table Header
      // +0 bytes: version (uint16)
      // +2 bytes: numPaletteEntries (uint16)
      // +4 bytes: numPalettes (uint16)
      final int numPaletteEntries = data.getUint16(cpalOffset + 2, Endian.big);
      final int numPalettes = data.getUint16(cpalOffset + 4, Endian.big);
      final int numColorRecords = data.getUint16(cpalOffset + 6, Endian.big);
      final int colorRecordsOffset = data.getUint32(cpalOffset + 8, Endian.big);

      if (numPaletteEntries == 0 || numPalettes < 2 || numColorRecords == 0) {
        // Must be >= 2 for the swap to work
        return fontBytes;
      }

      if (!_fits(cpalOffset + 12, numPalettes * 2, data.lengthInBytes)) {
        return fontBytes;
      }
      if (!_fits(
        cpalOffset + colorRecordsOffset,
        numColorRecords * 4,
        data.lengthInBytes,
      )) {
        return fontBytes;
      }

      // +6 bytes: numColorRecords (uint16)
      // +8 bytes: colorRecordsArrayOffset (uint32)
      // +12 bytes: colorRecordIndices (Array of uint16 of length numPalettes)

      // The first palette's color starting index is at CPAL offset + 12
      final int palette0IndexOffset = cpalOffset + 12;
      // The second palette's color starting index is at CPAL offset + 14
      final int palette1IndexOffset = cpalOffset + 14;

      // 4. The Patch
      final int palette0ColorIndex = data.getUint16(
        palette0IndexOffset,
        Endian.big,
      );
      final int palette1ColorIndex = data.getUint16(
        palette1IndexOffset,
        Endian.big,
      );

      if (palette0ColorIndex >= numColorRecords ||
          palette1ColorIndex >= numColorRecords) {
        return fontBytes;
      }

      // Swap the indices and write them back
      data.setUint16(palette0IndexOffset, palette1ColorIndex, Endian.big);
      data.setUint16(palette1IndexOffset, palette0ColorIndex, Endian.big);

      return fontBytes;
    } catch (e) {
      // Catch any unhandled buffer errors silently and return original bytes
      return fontBytes;
    }
  }

  static bool _fits(int offset, int length, int totalLength) {
    if (offset < 0 || length < 0 || offset > totalLength) return false;
    return length <= totalLength - offset;
  }
}
