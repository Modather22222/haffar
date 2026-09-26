import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/services/subscription_repository.dart';

void main() {
  group('SubscriptionOrder.fromJson', () {
    test('parses a full admin-list row', () {
      final o = SubscriptionOrder.fromJson({
        'id': 'ord-1',
        'user_id': 'u-1',
        'display_name': 'احمد',
        'operation_number': 'TRX-99',
        'receipt_path': 'u-1/receipt_1.jpg',
        'price_sdg': 49000,
        'status': 'pending',
        'created_at': '2026-09-26T10:00:00+00:00',
        'reviewed_at': null,
      });
      expect(o.id, 'ord-1');
      expect(o.displayName, 'احمد');
      expect(o.operationNumber, 'TRX-99');
      expect(o.priceSdg, 49000);
      expect(o.isPending, isTrue);
      expect(o.statusLabel, 'قيد المراجعة');
      expect(o.createdAt, isNotNull);
      expect(o.reviewedAt, isNull);
    });

    test('defaults missing optional fields', () {
      final o = SubscriptionOrder.fromJson(const {});
      expect(o.id, isEmpty);
      expect(o.priceSdg, 49000);
      expect(o.status, 'pending');
      expect(o.createdAt, isNull);
    });

    test('status helpers', () {
      SubscriptionOrder withStatus(String s) =>
          SubscriptionOrder.fromJson({'status': s});
      expect(withStatus('approved').isApproved, isTrue);
      expect(withStatus('approved').statusLabel, 'مقبول');
      expect(withStatus('rejected').isRejected, isTrue);
      expect(withStatus('rejected').statusLabel, 'مرفوض');
      expect(withStatus('pending').isPending, isTrue);
    });
  });
}
