import 'package:flutter/widgets.dart';

/// Upper-cases [text] for display in [languageCode].
///
/// `String.toUpperCase()` is locale-independent, so Turkish and Azeri `i`
/// becomes `I` instead of `İ` (and `ı` is handled correctly only by the
/// default mapping). Map the dotted and dotless i first for those languages.
String upperCaseFor(String languageCode, String text) {
  if (languageCode == 'tr' || languageCode == 'az') {
    return text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
  }
  return text.toUpperCase();
}

/// [upperCaseFor] using the locale of the nearest [Localizations].
String upperCaseIn(BuildContext context, String text) =>
    upperCaseFor(Localizations.localeOf(context).languageCode, text);
