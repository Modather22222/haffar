import 'package:flutter/material.dart';

import '../design_system/colors.dart';

/// "حفار برو" pill for subscribed users — orange primary background,
/// white label. Used on home (under the hearts count), leaderboard
/// (next to the XP), and profile (under the name).
class ProBadge extends StatelessWidget {
  const ProBadge({super.key, this.fontSize = 12});

  /// Label font size — use ~10 in tight spots (home/leaderboard),
  /// the default 12 on the profile header.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.6,
        vertical: fontSize * 0.28,
      ),
      decoration: BoxDecoration(
        color: HaffarColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'حفار برو',
        style: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }
}
