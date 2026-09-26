import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/providers/economy_provider.dart';

void main() {
  group('EconomyProvider subscription hydration', () {
    EconomyProvider hydrate(Map<String, dynamic> profile) {
      final e = EconomyProvider();
      e.hydrateFromProfile(profile);
      return e;
    }

    test('active period keeps the subscriber flag', () {
      final until = DateTime.now().toUtc().add(const Duration(days: 12));
      final e = hydrate({
        'is_subscribed': true,
        'subscribed_until': until.toIso8601String(),
      });
      expect(e.isSubscribed, isTrue);
      expect(e.subscriptionExpiresAt, until);
    });

    test('expired period drops the subscriber flag', () {
      final until = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final e = hydrate({
        'is_subscribed': true,
        'subscribed_until': until.toIso8601String(),
      });
      expect(e.isSubscribed, isFalse);
      expect(e.subscriptionExpiresAt, until);
    });

    test('legacy grant without an end date stays subscribed', () {
      final e = hydrate({'is_subscribed': true, 'subscribed_until': null});
      expect(e.isSubscribed, isTrue);
      expect(e.subscriptionExpiresAt, isNull);
    });

    test('non-subscriber stays non-subscriber', () {
      final e = hydrate({
        'is_subscribed': false,
        'subscribed_until': DateTime.now()
            .toUtc()
            .add(const Duration(days: 30))
            .toIso8601String(),
      });
      expect(e.isSubscribed, isFalse);
    });

    test('missing subscription fields behave like a free user', () {
      final e = hydrate({});
      expect(e.isSubscribed, isFalse);
      expect(e.subscriptionExpiresAt, isNull);
    });
  });
}
