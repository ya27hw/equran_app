import 'dart:convert';

import 'package:equran/features/halaqah_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 1, 10, 12);

  test(
    'session identifiers are random-looking and expiry is deterministic',
    () {
      final HalaqahSession session = HalaqahSession(now: () => now);

      expect(session.id, isNotEmpty);
      expect(session.id, isNot(contains('/')));
      expect(session.pairingSecret, isNot(session.id));
      expect(session.pairingInfo()['pairingSecret'], session.pairingSecret);
      expect(session.expiresAt, now.add(const Duration(hours: 8)));
      expect(session.isExpired(now.add(const Duration(hours: 7))), isFalse);
      expect(session.isExpired(session.expiresAt), isTrue);
    },
  );

  test('messages round-trip and reject unknown or oversized payloads', () {
    const HalaqahMessage message = HalaqahMessage(
      sessionId: 'session',
      senderId: 'sender',
      type: 'status',
      payload: <String, Object?>{'progress': 3},
    );
    final HalaqahMessage decoded = HalaqahMessage.decode(message.encode());
    expect(decoded.toMap(), message.toMap());

    final String unknownType = jsonEncode(<String, Object?>{
      'sessionId': 'session',
      'senderId': 'sender',
      'type': 'presence',
      'payload': <String, Object?>{},
    });
    expect(
      () => HalaqahMessage.decode(unknownType),
      throwsA(isA<HalaqahSecurityException>()),
    );

    final String large = jsonEncode(<String, Object?>{
      'sessionId': 'session',
      'senderId': 'sender',
      'type': 'status',
      'payload': <String, Object?>{'blob': 'x' * HalaqahMessage.maxBytes},
    });
    expect(
      () => HalaqahMessage.decode(large),
      throwsA(isA<HalaqahSecurityException>()),
    );
  });

  test('assignments validate canonical ayah ranges locally', () {
    final HalaqahAssignment assignment = HalaqahAssignment(
      id: 'assignment-1',
      sessionId: 'session',
      surah: 1,
      startAyah: 1,
      endAyah: 7,
      assignedAt: now,
    );
    expect(HalaqahAssignment.fromMap(assignment.toMap()), isNotNull);
    expect(
      HalaqahAssignment.fromMap(<String, Object?>{
        ...assignment.toMap(),
        'endAyah': 8,
      }),
      isNull,
    );
  });
}
