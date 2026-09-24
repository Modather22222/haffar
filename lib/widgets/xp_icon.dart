import 'package:flutter/material.dart';

/// Branded XP icon — replaces the old bolt icon + "XP" text everywhere.
/// Orange XP logo on transparency; avoid placing it directly on orange
/// backgrounds (wrap it in a light surface instead).
class XpIcon extends StatelessWidget {
  final double size;

  const XpIcon({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/xp.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
