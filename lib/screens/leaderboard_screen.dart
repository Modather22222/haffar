import '../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardScreen extends StatefulWidget {
  final VoidCallback onBack;
  const LeaderboardScreen({super.key, required this.onBack});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      setState(() { _loading = false; });
      return;
    }
    try {
      final startOfWeek = _startOfCurrentWeek();
      final result = await client.rpc('get_weekly_leaderboard', params: {
        'p_start': startOfWeek,
        'p_limit': 20,
        'p_current_user_id': uid,
      });
      if (mounted) {
        setState(() {
          _entries = (result as List<dynamic>)
              .map((r) => r as Map<String, dynamic>)
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  String _startOfCurrentWeek() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // 1=Mon, 6=Sat, 7=Sun
    final daysSinceSaturday = (dayOfWeek + 1) % 7;
    final start = DateTime(now.year, now.month, now.day - daysSinceSaturday);
    return start.toUtc().toIso8601String();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfbf9f9),
      appBar: AppBar(
        title: const Text('لوحة الصدارة'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        backgroundColor: Colors.white,
        foregroundColor: HaffarColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFcd7f32).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFcd7f32)),
              ),
              child: const Text(
                'دوري حفّار',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFcd7f32),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: HaffarColors.primary)))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(onPressed: _loadLeaderboard, icon: const Icon(Icons.refresh), label: const Text('إعادة التحميل')),
                  ]),
                ),
              )
            else if (_entries.isEmpty)
              Expanded(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('لا يوجد متصدرون هذا الأسبوع بعد',
                        style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 16, color: Color(0xFF6f7b64))),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(onPressed: _loadLeaderboard, icon: const Icon(Icons.refresh), label: const Text('إعادة التحميل')),
                  ]),
                ),
              )
            else ...[
              _buildPodium(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(child: _buildList()),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildPodium() {
    if (_entries.length < 3) return const SizedBox.shrink();
    final top3 = _entries.take(3).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _podiumCard(top3[1], rank: 2),
        _podiumCard(top3[0], rank: 1),
        _podiumCard(top3[2], rank: 3),
      ],
    );
  }

  Widget _podiumCard(Map<String, dynamic> entry, {required int rank}) {
    final heights = <int, double>{1: 130, 2: 100, 3: 80};
    final medals = <int, String>{1: '🥇', 2: '🥈', 3: '🥉'};
    final isCurrent = entry['is_current_user'] == true;
    final color = rank == 1 ? HaffarColors.primary : isCurrent ? const Color(0xFFcd7f32) : HaffarColors.surfaceHigh;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(children: [
        Text(medals[rank] ?? '#$rank', style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: heights[rank]!,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          (entry['display_name'] as String?) ?? 'البطل',
          style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 12, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${entry['week_xp']} XP',
          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 10, color: Color(0xFF6f7b64)),
        ),
      ]),
    );
  }

  Widget _buildList() {
    final entries = _entries.length > 3 ? _entries.skip(3).toList() : [];
    if (entries.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (ctx, i) {
        final entry = entries[i];
        final rank = i + 4;
        final isCurrent = entry['is_current_user'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isCurrent ? HaffarColors.primary.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isCurrent ? HaffarColors.primary : HaffarColors.outline.withValues(alpha: 0.1)),
          ),
          child: Row(children: [
            Text(
              '#$rank',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isCurrent ? HaffarColors.primary : const Color(0xFF3f4a36),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: isCurrent ? HaffarColors.primary : HaffarColors.grey5,
              child: Text(
                ((entry['display_name'] as String?) ?? 'ب')[0],
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry['display_name'] as String? ?? 'البطل',
                style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${entry['week_xp']} XP',
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: HaffarColors.primaryDark,
              ),
            ),
          ]),
        );
      },
    );
  }
}
