import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/economy_provider.dart';
import '../providers/content_provider.dart';
import '../providers/progress_provider.dart';
import '../design_system/colors.dart';
import '../models/subject.dart';
import '../utils/routes.dart';
import '../widgets/xp_icon.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeTab = 0;
  Timer? _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EconomyProvider>().syncHeartsFromServer();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _tick++;
      final economy = context.read<EconomyProvider>();
      final rem = economy.heartsRegenRemaining;
      if (rem != null && rem.inMilliseconds <= 500 && economy.hearts < 7) {
        economy.syncHeartsFromServer();
      } else if (_tick % 30 == 0) {
        economy.syncHeartsFromServer();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_activeTab == 1) {
      return LeaderboardScreen(onBack: () => setState(() => _activeTab = 0));
    }
    if (_activeTab == 2) {
      return ProfileScreen(onBack: () => setState(() => _activeTab = 0));
    }
    return Scaffold(
      body: SafeArea(child: const _HomeTab()),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _bottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: HaffarColors.outline, width: 0.5),
        ),
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
      onTap: () {
        setState(() => _activeTab = idx);
        if (idx == 0) context.read<EconomyProvider>().syncHeartsFromServer();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? HaffarColors.primary : HaffarColors.textSecondary,
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? HaffarColors.primary
                  : HaffarColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Home tab — watches narrow providers so econ chips don't rebuild on content
/// changes and subject grid doesn't rebuild on heart ticks.
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final economy = context.watch<EconomyProvider>();
    final progress = context.watch<ProgressProvider>();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statChip(const XpIcon(size: 16), '${economy.xp}'),
              _statChip(
                Image.asset(
                  'assets/icons/streak.png',
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                ),
                '${economy.streak} يوم',
              ),
              _statChip(
                Image.asset(
                  'assets/icons/lesson.png',
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                ),
                '${progress.completedLessons} درس',
              ),
              _statChipHeart(economy),
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
                  'مرحبا، ${progress.userName}!',
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
                  children: content.subjects
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
    final progress = ctx.watch<ProgressProvider>();
    final content = ctx.watch<ContentProvider>();
    final completed = progress.subjectCompletedCount(s.id);
    final total = content.lessonCountOf(s.id);
    final pct = total > 0 ? completed / total : 0.0;

    return InkWell(
      onTap: () => ctx.push(
        '${Routes.units}'
        '?subject=${Uri.encodeComponent(s.id)}',
        extra: s,
      ),
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
                child: Image.asset(
                  s.imageAsset!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                  Text(
                    '${(pct * 100).round()}%',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(Widget icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: HaffarColors.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
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

  Widget _statChipHeart(EconomyProvider economy) {
    final hearts = economy.hearts;
    final isFull = hearts >= 7;
    final rem = economy.heartsRegenRemaining;
    final progress = economy.heartsRegenProgress;
    final String label;
    if (isFull) {
      label = 'مكتمل';
    } else if (rem == null) {
      label = '--:--';
    } else {
      final totalSec = (rem.inMilliseconds + 999) ~/ 1000;
      final m = (totalSec ~/ 60).toString().padLeft(2, '0');
      final s = (totalSec % 60).toString().padLeft(2, '0');
      label = '$m:$s';
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: HaffarColors.surfaceHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/heart_small.svg',
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '$hearts',
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HaffarColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 64,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: HaffarColors.grey6,
              valueColor: const AlwaysStoppedAnimation<Color>(
                HaffarColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isFull
                ? HaffarColors.textPrimary
                : HaffarColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
