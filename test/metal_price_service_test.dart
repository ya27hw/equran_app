import 'package:equran/zakat/metal_price_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('MetalsLiveRateProvider', () {
    test('normalizes independent gold and silver spot rates', () async {
      final MockClient client = MockClient((http.Request request) async {
        expect(request.url.toString(), MetalsLiveRateProvider.endpoint);
        return http.Response('[{"gold":310.0,"silver":31.0}]', 200);
      });
      final MetalsLiveRateProvider provider = MetalsLiveRateProvider(
        client: client,
      );

      final MetalRateSnapshot snapshot = await provider.fetch(
        currency: 'usd',
        now: () => DateTime.utc(2026, 1, 2),
      );

      expect(snapshot.currency, 'USD');
      expect(snapshot.source, 'Metals.Live');
      expect(snapshot.goldPricePerGram, closeTo(310 / 31.1034768, 0.000001));
      expect(snapshot.silverPricePerGram, closeTo(31 / 31.1034768, 0.000001));
      expect(snapshot.isStale, isFalse);
      provider.close();
    });

    test(
      'rejects a response that cannot independently price both metals',
      () async {
        final MetalsLiveRateProvider provider = MetalsLiveRateProvider(
          client: MockClient((_) async => http.Response('{"gold":310}', 200)),
        );

        await expectLater(
          provider.fetch(currency: 'USD'),
          throwsA(isA<MetalRateException>()),
        );
        provider.close();
      },
    );

    test('does not silently convert an unsupported currency', () async {
      final MetalsLiveRateProvider provider = MetalsLiveRateProvider(
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      await expectLater(
        provider.fetch(currency: 'EUR'),
        throwsA(isA<MetalRateException>()),
      );
      provider.close();
    });
  });

  test('snapshot validation requires independent finite positive prices', () {
    final MetalRateSnapshot? valid =
        MetalRateSnapshot.fromMap(<String, Object?>{
          'goldPricePerGram': 75.0,
          'silverPricePerGram': 0.9,
          'source': 'manual',
          'fetchedAt': '2026-01-02T00:00:00Z',
          'currency': 'USD',
          'unit': 'USD/gram',
          'isStale': true,
        });
    expect(valid, isNotNull);
    expect(valid!.isStale, isTrue);
    expect(
      MetalRateSnapshot.fromMap(<String, Object?>{
        'goldPricePerGram': 75.0,
        'source': 'manual',
        'fetchedAt': '2026-01-02T00:00:00Z',
        'currency': 'USD',
        'unit': 'USD/gram',
      }),
      isNull,
    );
  });
}
