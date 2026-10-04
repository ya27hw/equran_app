import 'package:intl/intl.dart' show NumberFormat;

String formatCompactNumber(double value) {
  final String compact = value.toStringAsPrecision(3);
  return compact.contains('.')
      ? compact.replaceFirst(RegExp(r'\.?0+$'), '')
      : compact;
}

String formatDurationLabel(Duration duration) {
  final String minutes = duration.inMinutes
      .remainder(60)
      .toString()
      .padLeft(2, '0');
  final String seconds = duration.inSeconds
      .remainder(60)
      .toString()
      .padLeft(2, '0');
  if (duration.inHours > 0) {
    return '${duration.inHours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

/// Whole number with the locale's thousands separator, always in Western
/// digits: the app shows Western digits in every language, and intl would
/// switch ar / fa / bn to their own numerals.
String formatGroupedCount(int value, String localeName) =>
    NumberFormat.decimalPattern(_westernDigitLocale(localeName)).format(value);

/// Like [formatGroupedCount] but 10,000 and up become 12.3K / 1.2M, using
/// the locale's own decimal separator so the dot never means two things.
String formatCompactCount(int value, String localeName) {
  if (value < 10000) return formatGroupedCount(value, localeName);
  final NumberFormat oneDecimal = NumberFormat.decimalPatternDigits(
    locale: _westernDigitLocale(localeName),
    decimalDigits: 1,
  );
  return value >= 1000000
      ? '${oneDecimal.format(value / 1000000)}M'
      : '${oneDecimal.format(value / 1000)}K';
}

String _westernDigitLocale(String localeName) {
  final String language = localeName.split(RegExp('[_-]')).first;
  const westernDigitLanguages = <String>{'ar', 'fa', 'bn'};
  return westernDigitLanguages.contains(language) ? 'en' : localeName;
}
