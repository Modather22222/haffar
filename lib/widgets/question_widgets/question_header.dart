import '../../design_system/colors.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../xp_icon.dart';

class QuestionHeader extends StatelessWidget {
  final String pathTitle;
  final int xpReward;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final bool isFavorite;
  final VoidCallback? onTapFavorite;

  const QuestionHeader({
    super.key,
    required this.pathTitle,
    required this.xpReward,
    this.onBack,
    this.onSkip,
    this.isFavorite = false,
    this.onTapFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: HaffarColors.outline),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              pathTitle,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: HaffarColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onTapFavorite,
            child: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: HaffarColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: HaffarColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const XpIcon(size: 14),
                const SizedBox(width: 4),
                Text(
                  '$xpReward',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HaffarColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HintCard extends StatelessWidget {
  final String text;
  final IconData icon;
  const HintCard({
    super.key,
    required this.text,
    this.icon = Icons.lightbulb_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HaffarColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: HaffarColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: HaffarColors.primaryLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 14,
                color: Color(0xFF006590),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String text;
  const InfoCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HaffarColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: HaffarColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: HaffarColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 14,
                color: Color(0xFF6a3b00),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
