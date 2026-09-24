import '../design_system/colors.dart';
import '../services/xp_repository.dart';
import '../utils/app_error.dart';
import '../utils/routes.dart';
import '../widgets/league_countdown.dart';
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
  static const _medals = ['🥇', '🥈', '🥉'];
  static const _medalBg = {
    1: Color(0xFFFFF7DF), // gold
    2: Color(0xFFF4F5F6), // silver
    3: Color(0xFFFBEADF), // bronze
  };
  static const _medalBorder = {
    1: Color(0xFFE6B800),
    2: Color(0xFFB9BDC2),
    3: HaffarColors.leagueBronze,
  };

  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = AppError.notSignedIn;
          });
        }
        return;
      }
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
          _error = AppError.userMessage(
            e,
            fallback: 'تعذر تحميل لوحة الصدارة — حاول مرة أخرى',
          );
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
              const SizedBox(height: 14),
              LeagueCountdown(onWeekRollover: _loadLeaderboard),
              const SizedBox(height: 20),
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
              else
                Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (ctx, i) {
        final entry = _entries[i];
        final rank = i + 1;
        final isCurrent = entry['is_current_user'] == true;
        final medal = rank <= 3 ? _medals[rank - 1] : null;

        // Top 3 get medal-tinted rows; "you" keeps the primary border.
        var bg = isCurrent
            ? HaffarColors.primary.withValues(alpha: 0.1)
            : Colors.white;
        var border = isCurrent
            ? HaffarColors.primary
            : HaffarColors.outline.withValues(alpha: 0.1);
        if (medal != null) {
          bg = _medalBg[rank]!;
          border = isCurrent ? HaffarColors.primary : _medalBorder[rank]!;
        }

        return InkWell(
          onTap: () => _openProfile(entry),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Center(
                    child: medal != null
                        ? Text(medal, style: const TextStyle(fontSize: 18))
                        : Text(
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
                  ),
                ),
                const SizedBox(width: 8),
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
                    if (isCurrent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: HaffarColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'انت',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: HaffarColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
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
