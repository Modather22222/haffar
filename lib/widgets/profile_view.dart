import 'package:flutter/material.dart';

import '../design_system/colors.dart';
import 'xp_icon.dart';

/// Shared profile header: achievement banner, overlapping avatar, name,
/// league/grade subtitle, and a three-stat row.
///
/// Used by [ProfileScreen] (self) and [PublicProfileScreen] (others).
class ProfileView extends StatelessWidget {
  final String displayName;
  final String? subtitle;
  final int xp;
  final int streak;
  final int completedLessons;
  final int? weekXp;
  final String bannerAsset;
  final Widget Function(BuildContext context)? trailing;
  final String? avatarInitial;

  const ProfileView({
    super.key,
    required this.displayName,
    this.subtitle,
    required this.xp,
    required this.streak,
    required this.completedLessons,
    this.weekXp,
    required this.bannerAsset,
    this.trailing,
    this.avatarInitial,
  });

  String get _initial {
    if (avatarInitial != null && avatarInitial!.isNotEmpty) {
      return avatarInitial!;
    }
    if (displayName.isEmpty) return 'ح';
    return displayName[0];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Banner + avatar ──────────────────────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              bannerAsset,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 116,
              child: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: HaffarColors.primary,
                  ),
                  child: Center(
                    child: Text(
                      _initial,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 44),

        // ── Name & subtitle ──────────────────────────────────────────────
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: HaffarColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13,
              color: HaffarColors.outline,
            ),
          ),
        ],
        const SizedBox(height: 24),

        // ── Stats row ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              StatCard(
                icon: Image.asset(
                  'assets/icons/lesson.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                value: completedLessons.toString(),
                label: 'دروس مكتملة',
              ),
              const SizedBox(width: 10),
              StatCard(
                icon: Image.asset(
                  'assets/icons/streak.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                value: streak.toString(),
                label: 'أيام الحماسة',
              ),
              const SizedBox(width: 10),
              StatCard(
                icon: const XpIcon(size: 28),
                value: xp.toString(),
                label: 'مجموع النقاط',
              ),
            ],
          ),
        ),

        if (weekXp != null) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _WeekXpCard(weekXp: weekXp!),
          ),
        ],

        if (trailing != null) ...[trailing!(context)],
      ],
    );
  }
}

/// Three-column stat tile with icon, value, and label.
class StatCard extends StatelessWidget {
  final Widget icon;
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: HaffarColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                color: HaffarColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekXpCard extends StatelessWidget {
  final int weekXp;

  const _WeekXpCard({required this.weekXp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekXp.toString(),
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: HaffarColors.primaryDark,
                ),
              ),
              const SizedBox(width: 6),
              const XpIcon(size: 20),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'نقاط هذا الأسبوع',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              color: HaffarColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}
