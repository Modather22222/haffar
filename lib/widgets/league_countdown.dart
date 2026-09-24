import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design_system/colors.dart';
import '../services/xp_repository.dart';
import '../utils/app_logger.dart';

/// Days / hours / minutes remaining in the current دوري حفّار week,
/// rendered as three dark cubes (يوم · ساعة · دقيقة).
///
/// Timing follows the same server-anchored pattern as the heart-regen
/// countdown: the server RPC returns week_end and its own NOW(); the widget
/// stores remaining-at-fetch and ticks against elapsed device time, so a
/// wrong device clock never skews it. Re-syncs every minute, and fires
/// [onWeekRollover] once when the week ends so the host can reload data.
class LeagueCountdown extends StatefulWidget {
  final VoidCallback? onWeekRollover;
  const LeagueCountdown({super.key, this.onWeekRollover});

  @override
  State<LeagueCountdown> createState() => _LeagueCountdownState();
}

class _LeagueCountdownState extends State<LeagueCountdown> {
  Timer? _ticker;
  Timer? _resync;
  Duration? _serverRemaining;
  DateTime? _fetchedAt;
  bool _rolledOver = false;

  @override
  void initState() {
    super.initState();
    _sync();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _resync = Timer.periodic(const Duration(minutes: 1), (_) => _sync());
  }

  Future<void> _sync() async {
    try {
      final window = await XpRepository(
        Supabase.instance.client,
      ).getLeagueWindow();
      if (window == null || !mounted) return;
      var remaining = window.end.difference(window.serverNow);
      if (remaining.isNegative) remaining = Duration.zero;
      setState(() {
        _serverRemaining = remaining;
        _fetchedAt = DateTime.now().toUtc();
        _rolledOver = false;
      });
    } catch (e, st) {
      // Background re-sync — keep last known window, retry next minute.
      AppLog.warn('league window sync failed: $e');
      AppLog.error('league window sync', e, st);
    }
  }

  /// Server-anchored remaining time, monotonic in device elapsed time.
  Duration get _remaining {
    final server = _serverRemaining;
    final fetchedAt = _fetchedAt;
    if (server == null || fetchedAt == null) return Duration.zero;
    final elapsed = DateTime.now().toUtc().difference(fetchedAt);
    final rem = server - elapsed;
    return rem.isNegative ? Duration.zero : rem;
  }

  void _onTick() {
    if (!mounted) return;
    if (_serverRemaining != null && _remaining <= Duration.zero) {
      if (!_rolledOver) {
        _rolledOver = true;
        widget.onWeekRollover?.call();
        _sync(); // pull the new week's window right away
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _resync?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rem = _remaining;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CountdownCube(label: 'يوم', value: rem.inDays),
        const SizedBox(width: 10),
        _CountdownCube(label: 'ساعة', value: rem.inHours % 24),
        const SizedBox(width: 10),
        _CountdownCube(label: 'دقيقة', value: rem.inMinutes % 60),
      ],
    );
  }
}

class _CountdownCube extends StatelessWidget {
  final String label;
  final int value;
  const _CountdownCube({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 92,
      decoration: BoxDecoration(
        color: HaffarColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
