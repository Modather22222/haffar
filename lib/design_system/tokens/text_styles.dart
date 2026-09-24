import 'package:flutter/material.dart';

import '../colors.dart';

class HaffarTextStyles {
  HaffarTextStyles._();

  // BeVietnamPro is the only heavy face declared in pubspec.yaml.
  static const String _family = 'BeVietnamPro';

  static const String fontFamily = _family;

  static TextStyle header = const TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    letterSpacing: -2,
    color: HaffarTextColors.textPrimary,
  );

  static TextStyle primaryTitle = const TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    letterSpacing: -2,
    color: HaffarTextColors.textPrimary,
  );

  static TextStyle goalTitle = const TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w700,
    fontSize: 21,
    letterSpacing: -0.5,
    color: HaffarTextColors.textPrimary,
  );

  static TextStyle primary = const TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w400,
    fontSize: 20,
    letterSpacing: 3,
    color: HaffarTextColors.textPrimary,
  );

  static TextStyle primaryBold = const TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    letterSpacing: 3,
    color: HaffarTextColors.textPrimary,
  );

  static TextStyle smallBold = const TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    letterSpacing: -2,
    color: HaffarTextColors.textPrimary,
  );

  static TextStyle buttonText = const TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    letterSpacing: -2,
    color: HaffarTextColors.white,
  );

  static TextStyle subtext = const TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w400,
    fontSize: 18,
    letterSpacing: -1,
    color: HaffarTextColors.textSecondary,
  );

  static TextStyle subtext2 = const TextStyle(
    fontFamily: _family,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: -1,
    color: HaffarTextColors.textSecondary,
  );
}

class HaffarTextColors {
  HaffarTextColors._();
  static const Color textPrimary = HaffarColors.grey1;
  static const Color textSecondary = HaffarColors.grey2;
  static const Color textTertiary = HaffarColors.grey3;
  static const Color textQuaternary = HaffarColors.grey5;
  static const Color white = Colors.white;
}
