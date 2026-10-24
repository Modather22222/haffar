import '../../design_system/colors.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../markdown_text.dart';

/// Shared small cards rendered under a question (hint/info). The old
/// per-question header with the XP chip was retired from the design —
/// the quiz screen's own bar owns the top row now.


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
            child: MarkdownText(
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
            child: MarkdownText(
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
