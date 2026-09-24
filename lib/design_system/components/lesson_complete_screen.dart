import 'package:flutter/material.dart';

import '../colors.dart';
import 'buttons/button_general_primary.dart';
import '../../widgets/mascot.dart';
import '../../widgets/xp_icon.dart';

/// Full-screen quiz/lesson completion (replaces the mid-screen dialog).
///
/// Layout mirrors the reference "Lesson Complete" design: illustration,
/// gold title, three stat cards (XP / accuracy / time), and a fixed
/// bottom primary action.
class LessonCompleteScreen extends StatelessWidget {
  final MascotPose pose;
  final String title;
  final int xpGained;
  final int accuracyPercent;
  final String accuracyLabel;
  final Duration duration;
  final String buttonLabel;
  final VoidCallback onContinue;

  const LessonCompleteScreen({
    super.key,
    required this.pose,
    required this.title,
    required this.xpGained,
    required this.accuracyPercent,
    required this.accuracyLabel,
    required this.duration,
    this.buttonLabel = 'استمرار',
    required this.onContinue,
  });

  static const double _maxWidth = 430;

  /// Pushes the full-screen complete UI. When [popUnderneath] is true,
  /// continuing also pops the quiz route under this screen.
  static Future<void> show(
    BuildContext context, {
    required MascotPose pose,
    required String title,
    int xpGained = 0,
    int accuracyPercent = 0,
    String accuracyLabel = '',
    Duration duration = Duration.zero,
    String buttonLabel = 'استمرار',
    bool popUnderneath = false,
  }) {
    final nav = Navigator.of(context);
    return nav.push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        fullscreenDialog: true,
        pageBuilder: (context, animation, secondaryAnimation) =>
            LessonCompleteScreen(
              pose: pose,
              title: title,
              xpGained: xpGained,
              accuracyPercent: accuracyPercent,
              accuracyLabel: accuracyLabel,
              duration: duration,
              buttonLabel: buttonLabel,
              onContinue: () {
                nav.pop();
                if (popUnderneath) nav.pop();
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HaffarColors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [_header()],
                    ),
                  ),
                ),
                _bottomAction(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Mascot(pose: pose, size: 220),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 31,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: HaffarColors.primary,
          ),
        ),
        const SizedBox(height: 36),
        _statsRow(),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatCard(
          base: HaffarColors.primary,
          valueColor: HaffarColors.primary,
          label: 'الخبرة',
          labelLeft: 28,
          icon: const XpIcon(size: 20),
          value: '$xpGained',
        ),
        const SizedBox(width: 16),
        _StatCard(
          base: const Color(0xFF58CC02),
          valueColor: const Color(0xFF58A700),
          label: 'الدقة',
          labelLeft: 34,
          icon: const Icon(Icons.gps_fixed, size: 20, color: Color(0xFF58CC02)),
          value: '$accuracyPercent%',
          valueSuffix: accuracyLabel.isEmpty ? null : accuracyLabel,
        ),
        const SizedBox(width: 16),
        _StatCard(
          base: const Color(0xFF1CB0F6),
          valueColor: const Color(0xFF1CB0F6),
          label: 'الوقت',
          labelLeft: 30,
          icon: const Icon(Icons.timer, size: 20, color: Color(0xFF1CB0F6)),
          value: _formatDuration(duration),
        ),
      ],
    );
  }

  Widget _bottomAction(BuildContext context) {
    return Container(
      color: HaffarColors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: HaffarPrimaryButton(
        label: buttonLabel,
        fullWidth: true,
        onPressed: onContinue,
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${_toArabicNum(m)}:${_toArabicNum(s).padLeft(2, '٠')}';
  }

  static String _toArabicNum(int n) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => arabicDigits[int.parse(c)]).join();
  }
}

/// 102 × 86 stat card: colored base strip + white face with icon + value.
class _StatCard extends StatelessWidget {
  final Color base;
  final Color valueColor;
  final String label;
  final double labelLeft;
  final Widget icon;
  final String value;
  final String? valueSuffix;

  const _StatCard({
    required this.base,
    required this.valueColor,
    required this.label,
    required this.labelLeft,
    required this.icon,
    required this.value,
    this.valueSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 102,
      height: 86,
      child: Stack(
        children: [
          Container(
            width: 102,
            height: 86,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          Positioned(
            left: 0,
            top: 20,
            width: 102,
            height: 66,
            child: Container(
              decoration: BoxDecoration(
                color: HaffarColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: base, width: 2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon,
                      const SizedBox(width: 6),
                      Text(
                        value,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: valueColor,
                        ),
                      ),
                    ],
                  ),
                  if (valueSuffix != null)
                    Text(
                      valueSuffix!,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: valueColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: labelLeft,
            top: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: HaffarColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
