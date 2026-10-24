import 'package:flutter/foundation.dart';

import '../utils/local_prefs.dart';

/// Broker for the "subscription approved" celebration modal.
///
/// Shows the modal exactly once per approved subscription. The celebrated
/// marker is the subscription's `subscribed_until` timestamp (milliseconds):
/// approving a renewal extends `subscribed_until`, which produces a new
/// marker and therefore a fresh celebration — while the same period never
/// celebrates twice, even across app restarts (persisted via LocalPrefs).
class SubscriptionCelebration {
  SubscriptionCelebration._();

  static final SubscriptionCelebration instance =
      SubscriptionCelebration._();

  /// Last `subscribed_until` (millis) awaiting display; 0 = nothing pending.
  final ValueNotifier<int> pending = ValueNotifier<int>(0);

  /// Cached celebrated marker — avoids a prefs round-trip on every hydrate.
  int _celebrated = 0;
  bool _celebratedLoaded = false;

  /// Keys already queued for display this session, so concurrent hydrates
  /// (session restore + subscription screen refresh) never double-show.
  final Set<int> _queued = {};

  /// Feed the latest `subscribed_until` after a profile hydrate.
  Future<void> consider(int subscribedUntilMillis) async {
    if (subscribedUntilMillis <= 0) return; // not subscribed / open grant
    if (!_celebratedLoaded) {
      _celebrated = await LocalPrefs.readCelebratedSubscriptionUntil();
      _celebratedLoaded = true;
    }
    if (subscribedUntilMillis <= _celebrated) return; // already celebrated
    if (!_queued.add(subscribedUntilMillis)) return; // already queued
    if (pending.value > subscribedUntilMillis) return; // stale out-of-order hydrate
    pending.value = subscribedUntilMillis;
  }

  /// Called once the modal actually showed and the user dismissed it —
  /// persists the marker so the same approval never celebrates again.
  Future<void> dismiss() async {
    final key = pending.value;
    if (key <= 0) return;
    pending.value = 0;
    _celebrated = key;
    await LocalPrefs.writeCelebratedSubscriptionUntil(key);
  }
}
