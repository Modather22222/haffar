import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../design_system/colors.dart';
import '../models/subject.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'units_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      body: SafeArea(
        child: _buildCurrentTab(provider),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _buildCurrentTab(AppProvider p) {
    switch (_activeTab) {
      case 1: return LeaderboardScreen(onBack: () => setState(() => _activeTab = 0));
      case 2: return ProfileScreen(onBack: () => setState(() => _activeTab = 0));
      default: return _buildHome(p);
    }
  }

  Widget _buildHome(AppProvider p) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statChip(Icons.bolt, '${p.xp} XP'),
              _statChip(Icons.local_fire_department, '${p.streak} يوم'),
              _statChip(Icons.school, '${p.completedLessons} درس'),
              _statChipHeart(p.hearts),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  'مرحباُ، ${p.userName}!',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'المواد',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: context
                      .watch<AppProvider>()
                      .subjects
                      .map((s) => _subjectCard(s, context))
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _subjectCard(Subject s, BuildContext ctx) {
    final p = ctx.watch<AppProvider>();
    final completed = p.subjectCompletedCount(s.id);
    final total = p.lessonCountOf(s.id);
    final progress = total > 0 ? completed / total : 0.0;

    return InkWell(
      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => UnitsScreen(subjectId: s.id, subject: s))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HaffarColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HaffarColors.primary),
        ),
        child: Column(
          children: [
            if (s.imageAsset != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(s.imageAsset!, width: 72, height: 72, fit: BoxFit.cover),
              )
            else
              Text(s.icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              s.name,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: HaffarColors.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: HaffarColors.primary),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChipHeart(int hearts) {
    final color = hearts > 0 ? HaffarColors.primary : HaffarColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: HaffarColors.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$hearts',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: HaffarColors.outline, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, LucideIcons.home, 'الرئيسية'),
          _navItem(1, LucideIcons.trophy, 'المتصدرون'),
          _navItem(2, LucideIcons.user, 'حسابي'),
        ],
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final isActive = _activeTab == idx;
    return InkWell(
      onTap: () => setState(() => _activeTab = idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: isActive ? HaffarColors.primary : HaffarColors.textSecondary),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive ? HaffarColors.primary : HaffarColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
