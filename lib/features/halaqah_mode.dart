import 'dart:convert';
import 'dart:math';

class HalaqahSecurityException implements Exception {
  const HalaqahSecurityException(this.message);

  final String message;
  @override
  String toString() => 'HalaqahSecurityException: $message';
}

class HalaqahSession {
  HalaqahSession({String? id, String? pairingSecret, DateTime Function()? now})
    : this._withCreatedAt(
        id ?? _secureId(),
        pairingSecret ?? _secureId(),
        (now ?? DateTime.now)().toUtc(),
      );

  HalaqahSession._withCreatedAt(this.id, this.pairingSecret, this.createdAt)
    : expiresAt = createdAt.add(const Duration(hours: 8));

  final String id;
  final String pairingSecret;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !now.toUtc().isBefore(expiresAt);

  Map<String, Object?> pairingInfo() => <String, Object?>{
    'sessionId': id,
    'pairingSecret': pairingSecret,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };

  static String _secureId() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(18, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}

class HalaqahMessage {
  const HalaqahMessage({
    required this.sessionId,
    required this.senderId,
    required this.type,
    required this.payload,
  });

  static const int maxBytes = 64 * 1024;
  static const Set<String> allowedTypes = <String>{
    'hello',
    'assignment',
    'status',
    'correction',
    'end',
  };

  final String sessionId;
  final String senderId;
  final String type;
  final Map<String, Object?> payload;

  Map<String, Object?> toMap() => <String, Object?>{
    'sessionId': sessionId,
    'senderId': senderId,
    'type': type,
    'payload': payload,
  };

  String encode() {
    _validateShape();
    final String value = jsonEncode(toMap());
    if (utf8.encode(value).length > maxBytes) {
      throw const HalaqahSecurityException('Halaqah message is too large.');
    }
    return value;
  }

  static HalaqahMessage decode(String encoded) {
    if (utf8.encode(encoded).length > maxBytes) {
      throw const HalaqahSecurityException('Halaqah message is too large.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } catch (_) {
      throw const HalaqahSecurityException('Halaqah message is invalid.');
    }
    if (decoded is! Map ||
        decoded['sessionId'] is! String ||
        decoded['senderId'] is! String ||
        decoded['type'] is! String ||
        decoded['payload'] is! Map) {
      throw const HalaqahSecurityException('Halaqah message shape is invalid.');
    }
    final String type = decoded['type'] as String;
    if (!allowedTypes.contains(type)) {
      throw const HalaqahSecurityException(
        'Halaqah message type is not allowed.',
      );
    }
    final HalaqahMessage message = HalaqahMessage(
      sessionId: decoded['sessionId'] as String,
      senderId: decoded['senderId'] as String,
      type: type,
      payload: (decoded['payload'] as Map).map<String, Object?>(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      ),
    );
    message._validateShape();
    return message;
  }

  void _validateShape() {
    if (sessionId.trim().isEmpty || sessionId.length > 128) {
      throw const HalaqahSecurityException(
        'Halaqah session identifier is invalid.',
      );
    }
    if (senderId.trim().isEmpty || senderId.length > 128) {
      throw const HalaqahSecurityException(
        'Halaqah sender identifier is invalid.',
      );
    }
    if (!allowedTypes.contains(type)) {
      throw const HalaqahSecurityException(
        'Halaqah message type is not allowed.',
      );
    }
    if (payload.length > 256 || !_isJsonSafe(payload)) {
      throw const HalaqahSecurityException(
        'Halaqah message payload is invalid.',
      );
    }
  }

  static bool _isJsonSafe(Object? value, {int depth = 0}) {
    if (depth > 8) return false;
    if (value == null || value is String || value is bool || value is num) {
      return value is! String || value.length <= 16 * 1024;
    }
    if (value is List) {
      return value.length <= 256 &&
          value.every((Object? item) => _isJsonSafe(item, depth: depth + 1));
    }
    if (value is Map) {
      return value.length <= 256 &&
          value.entries.every((MapEntry<Object?, Object?> entry) {
            return entry.key is String &&
                (entry.key as String).length <= 128 &&
                _isJsonSafe(entry.value, depth: depth + 1);
          });
    }
    return false;
  }
}
