import '../design_system/colors.dart';
import '../services/xp_repository.dart';
import '../utils/routes.dart';
import '../widgets/xp_icon.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      setState(() {
        _loading = false;
      });
      return;
    }
    try {
      final entries = await XpRepository(client).getLeaderboard(20);
      if (mounted) {
        setState(() {
          _entries = entries;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _openProfile(Map<String, dynamic> entry) {
    final userId = entry['user_id'] as String?;
    if (userId == null) return;
    final name = entry['display_name'] as String? ?? '';
    context.push(
      '${Routes.publicProfile}?uid=$userId&name=${Uri.encodeComponent(name)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HaffarColors.bgPage,
      appBar: AppBar(
        title: const Text('لوحة الصدارة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        backgroundColor: Colors.white,
        foregroundColor: HaffarColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: HaffarColors.leagueBronze.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HaffarColors.leagueBronze),
                ),
                child: const Text(
                  'دوري حفّار',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: HaffarColors.leagueBronze,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: HaffarColors.primary,
                    ),
                  ),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadLeaderboard,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة التحميل'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_entries.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'لا يوجد متصدرون هذا الأسبوع بعد',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 16,
                            color: HaffarColors.outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadLeaderboard,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة التحميل'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildPodium(),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Expanded(child: _buildList()),
              ],
            ],
          ),
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
    final color = rank == 1
        ? HaffarColors.primary
        : isCurrent
        ? HaffarColors.leagueBronze
        : HaffarColors.surfaceHigh;
    return InkWell(
      onTap: () => _openProfile(entry),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Text(
              medals[rank] ?? '#$rank',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Container(
              width: 60,
              height: heights[rank]!,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
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
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry['week_xp']}',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10,
                    color: HaffarColors.outline,
                  ),
                ),
                const SizedBox(width: 3),
                const XpIcon(size: 12),
              ],
            ),
          ],
        ),
      ),
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
        return InkWell(
          onTap: () => _openProfile(entry),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCurrent
                  ? HaffarColors.primary.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent
                    ? HaffarColors.primary
                    : HaffarColors.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isCurrent
                        ? HaffarColors.primary
                        : HaffarColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isCurrent
                      ? HaffarColors.primary
                      : HaffarColors.grey5,
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
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entry['week_xp']}',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HaffarColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const XpIcon(size: 14),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
