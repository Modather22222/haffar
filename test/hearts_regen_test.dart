import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/utils/game_constants.dart';

/// Pure regen math mirroring HeartsRepository/server get_hearts:
/// +1 heart per heartRegenInterval, capped at maxHearts.
int regainedHearts({
  required int hearts,
  required DateTime updatedAt,
  required DateTime now,
}) {
  if (hearts >= GameConstants.maxHearts) return 0;
  final elapsed = now.difference(updatedAt);
  if (elapsed.isNegative) return 0;
  final gained =
      elapsed.inMilliseconds ~/ GameConstants.heartRegenInterval.inMilliseconds;
  final wouldBe = hearts + gained;
  return wouldBe > GameConstants.maxHearts ? 0 : gained;
}

Duration regenRemaining({
  required int hearts,
  required DateTime updatedAt,
  required DateTime now,
}) {
  if (hearts >= GameConstants.maxHearts) return Duration.zero;
  final next = updatedAt.add(GameConstants.heartRegenInterval);
  final rem = next.difference(now);
  return rem.isNegative ? Duration.zero : rem;
}

void main() {
  group('heart regeneration math', () {
    final interval = GameConstants.heartRegenInterval;

    test('no regain before interval elapses', () {
      final updated = DateTime.utc(2026, 9, 24, 10, 0);
      final now = updated.add(interval - const Duration(seconds: 1));
      expect(regainedHearts(hearts: 5, updatedAt: updated, now: now), 0);
    });

    test('regains exactly one heart after one interval', () {
      final updated = DateTime.utc(2026, 9, 24, 10, 0);
      final now = updated.add(interval);
      expect(regainedHearts(hearts: 5, updatedAt: updated, now: now), 1);
    });

    test('never exceeds maxHearts', () {
      final updated = DateTime.utc(2026, 9, 24, 10, 0);
      final now = updated.add(interval * 100);
      final hearts = GameConstants.maxHearts - 1;
      final wouldBe =
          hearts + regainedHearts(hearts: hearts, updatedAt: updated, now: now);
      expect(wouldBe, lessThanOrEqualTo(GameConstants.maxHearts));
    });

    test('full hearts report zero remaining', () {
      final rem = regenRemaining(
        hearts: GameConstants.maxHearts,
        updatedAt: DateTime.utc(2026, 9, 24),
        now: DateTime.utc(2026, 9, 24),
      );
      expect(rem, Duration.zero);
    });

    test('remaining counts down monotonically', () {
      final updated = DateTime.utc(2026, 9, 24, 10, 0);
      final r1 = regenRemaining(hearts: 3, updatedAt: updated, now: updated);
      final r2 = regenRemaining(
        hearts: 3,
        updatedAt: updated,
        now: updated.add(const Duration(minutes: 4)),
      );
      expect(r2, lessThan(r1));
    });
  });
}
