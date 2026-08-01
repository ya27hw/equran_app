import 'package:hive_flutter/hive_flutter.dart';

class ZakatRecord {
  ZakatRecord({
    required this.id,
    required this.date,
    required this.cash,
    required this.investments,
    required this.goldGrams,
    required this.goldPrice,
    required this.silverGrams,
    required this.silverPrice,
    required this.liabilities,
    required this.nisabType,
    required this.nisabValue,
    required this.zakatDue,
    this.zakatPaid = 0.0,
    this.detailsJson,
  });

  final String id;
  final DateTime date;
  final double cash;
  final double investments;
  final double goldGrams;
  final double goldPrice;
  final double silverGrams;
  final double silverPrice;
  final double liabilities;
  final String nisabType; // 'gold' or 'silver'
  final double nisabValue;
  final double zakatDue;
  double zakatPaid;

  /// Forward-compatible rich data for new calculator categories.
  /// Stores JSON of additional line items (stocks, livestock, business, etc.).
  final Map<String, dynamic>? detailsJson;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'cash': cash,
      'investments': investments,
      'goldGrams': goldGrams,
      'goldPrice': goldPrice,
      'silverGrams': silverGrams,
      'silverPrice': silverPrice,
      'liabilities': liabilities,
      'nisabType': nisabType,
      'nisabValue': nisabValue,
      'zakatDue': zakatDue,
      'zakatPaid': zakatPaid,
      if (detailsJson != null) 'detailsJson': detailsJson,
    };
  }

  factory ZakatRecord.fromMap(Map<dynamic, dynamic> map) {
    return ZakatRecord(
      id: map['id']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      cash: (map['cash'] as num?)?.toDouble() ?? 0.0,
      investments: (map['investments'] as num?)?.toDouble() ?? 0.0,
      goldGrams: (map['goldGrams'] as num?)?.toDouble() ?? 0.0,
      goldPrice: (map['goldPrice'] as num?)?.toDouble() ?? 0.0,
      silverGrams: (map['silverGrams'] as num?)?.toDouble() ?? 0.0,
      silverPrice: (map['silverPrice'] as num?)?.toDouble() ?? 0.0,
      liabilities: (map['liabilities'] as num?)?.toDouble() ?? 0.0,
      nisabType: map['nisabType']?.toString() ?? 'silver',
      nisabValue: (map['nisabValue'] as num?)?.toDouble() ?? 0.0,
      zakatDue: (map['zakatDue'] as num?)?.toDouble() ?? 0.0,
      zakatPaid: (map['zakatPaid'] as num?)?.toDouble() ?? 0.0,
      detailsJson: map['detailsJson'] is Map
          ? Map<String, dynamic>.from(map['detailsJson'] as Map)
          : null,
    );
  }
}

class ZakatHistoryDB {
  ZakatHistoryDB._();
  static final ZakatHistoryDB instance = ZakatHistoryDB._();

  static const String _boxName = 'zakah_history_box_v1';
  late final Box<dynamic> _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  List<ZakatRecord> getAllRecords() {
    final List<dynamic> values = _box.values.toList();
    return values
        .map((dynamic e) {
          if (e is Map) {
            return ZakatRecord.fromMap(e);
          }
          return null;
        })
        .whereType<ZakatRecord>()
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveRecord(ZakatRecord record) async {
    await _box.put(record.id, record.toMap());
  }

  Future<void> deleteRecord(String id) async {
    await _box.delete(id);
  }

  Future<void> updatePaidAmount(String id, double paidAmount) async {
    final dynamic existing = _box.get(id);
    if (existing is Map) {
      final ZakatRecord record = ZakatRecord.fromMap(existing);
      record.zakatPaid = paidAmount;
      await _box.put(id, record.toMap());
    }
  }

  /// Exposes a defensive copy for the versioned backup service. The returned
  /// values remain owned by Hive and are never mutated by callers.
  Box<dynamic> exportBox() => _box;

  Future<void> replaceBox(Map<dynamic, dynamic> values) async {
    await _box.clear();
    await _box.putAll(values);
  }

  dynamic get listener => _box.listenable();
}
