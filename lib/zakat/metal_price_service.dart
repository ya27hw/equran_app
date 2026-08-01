import 'dart:convert';

import 'package:http/http.dart' as http;

/// A transparent pair of independently supplied metal rates.
///
/// Prices are normalized to the declared [unit] and [currency]. The snapshot
/// deliberately stores both metals separately; callers must never derive one
/// metal's rate from the other and label the result as live.
class MetalRateSnapshot {
  const MetalRateSnapshot({
    required this.goldPricePerGram,
    required this.silverPricePerGram,
    required this.source,
    required this.fetchedAt,
    required this.currency,
    this.unit = 'currency/gram',
    this.isStale = false,
  });

  final double goldPricePerGram;
  final double silverPricePerGram;
  final String source;
  final DateTime fetchedAt;
  final String currency;
  final String unit;
  final bool isStale;

  MetalRateSnapshot copyWith({
    double? goldPricePerGram,
    double? silverPricePerGram,
    String? source,
    DateTime? fetchedAt,
    String? currency,
    String? unit,
    bool? isStale,
  }) {
    return MetalRateSnapshot(
      goldPricePerGram: goldPricePerGram ?? this.goldPricePerGram,
      silverPricePerGram: silverPricePerGram ?? this.silverPricePerGram,
      source: source ?? this.source,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      currency: currency ?? this.currency,
      unit: unit ?? this.unit,
      isStale: isStale ?? this.isStale,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'goldPricePerGram': goldPricePerGram,
    'silverPricePerGram': silverPricePerGram,
    'source': source,
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'currency': currency,
    'unit': unit,
    'isStale': isStale,
  };

  static MetalRateSnapshot? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final double? gold = _finitePositive(raw['goldPricePerGram']);
    final double? silver = _finitePositive(raw['silverPricePerGram']);
    final String? source = _nonEmptyString(raw['source']);
    final String? currency = _nonEmptyString(raw['currency']);
    final String? unit = _nonEmptyString(raw['unit']);
    final DateTime? fetchedAt = _dateTime(raw['fetchedAt']);
    if (gold == null ||
        silver == null ||
        source == null ||
        currency == null ||
        unit == null ||
        fetchedAt == null) {
      return null;
    }
    return MetalRateSnapshot(
      goldPricePerGram: gold,
      silverPricePerGram: silver,
      source: source,
      fetchedAt: fetchedAt,
      currency: currency,
      unit: unit,
      isStale: raw['isStale'] == true,
    );
  }

  static double? _finitePositive(Object? value) {
    if (value is! num) return null;
    final double result = value.toDouble();
    return result.isFinite && result > 0 ? result : null;
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static DateTime? _dateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}

class MetalRateException implements Exception {
  const MetalRateException(this.message);

  final String message;

  @override
  String toString() => 'MetalRateException: $message';
}

abstract interface class MetalRateProvider {
  Future<MetalRateSnapshot> fetch({
    required String currency,
    DateTime Function()? now,
  });
}

/// Provider for the public Metals.Live spot endpoint.
///
/// The endpoint supplies gold and silver as separate fields in USD per troy
/// ounce. Currency conversion is intentionally not guessed; callers receive a
/// failure for unsupported currencies and can use a manual or cached value.
class MetalsLiveRateProvider implements MetalRateProvider {
  MetalsLiveRateProvider({http.Client? client})
    : _client = client ?? http.Client();

  static const String endpoint = 'https://api.metals.live/v1/spot';
  static const double troyOunceGrams = 31.1034768;

  final http.Client _client;

  void close() => _client.close();

  @override
  Future<MetalRateSnapshot> fetch({
    required String currency,
    DateTime Function()? now,
  }) async {
    final String normalizedCurrency = currency.trim().toUpperCase();
    if (normalizedCurrency != 'USD') {
      throw const MetalRateException(
        'This live provider reports USD only; no currency conversion was applied.',
      );
    }

    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      throw const MetalRateException(
        'The independent metal-rate provider failed before returning rates.',
      );
    }
    if (response.statusCode != 200) {
      throw MetalRateException(
        'The independent metal-rate provider returned HTTP ${response.statusCode}.',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const MetalRateException(
        'The independent metal-rate response was invalid.',
      );
    }
    final Map<String, Object?> values = _firstMap(decoded);
    final double? goldPerOunce = _positiveNumber(values['gold']);
    final double? silverPerOunce = _positiveNumber(values['silver']);
    if (goldPerOunce == null || silverPerOunce == null) {
      throw const MetalRateException(
        'The independent response did not contain both gold and silver rates.',
      );
    }

    return MetalRateSnapshot(
      goldPricePerGram: goldPerOunce / troyOunceGrams,
      silverPricePerGram: silverPerOunce / troyOunceGrams,
      source: 'Metals.Live',
      fetchedAt: (now ?? DateTime.now)().toUtc(),
      currency: normalizedCurrency,
      unit: 'USD/gram',
    );
  }

  static Map<String, Object?> _firstMap(Object? decoded) {
    if (decoded is Map) {
      return decoded.map<String, Object?>(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      );
    }
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      final Map first = decoded.first as Map;
      return first.map<String, Object?>(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      );
    }
    return const <String, Object?>{};
  }

  static double? _positiveNumber(Object? value) {
    if (value is! num) return null;
    final double result = value.toDouble();
    return result.isFinite && result > 0 ? result : null;
  }
}
