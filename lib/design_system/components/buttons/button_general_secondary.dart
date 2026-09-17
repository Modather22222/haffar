import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../../colors.dart';

enum HaffarSecondaryButtonState { enabled, pressed, disabled }

class HaffarSecondaryButton extends StatelessWidget {
  final HaffarSecondaryButtonState state;
  final String label;
  final VoidCallback? onPressed;

  const HaffarSecondaryButton({
    super.key,
    this.state = HaffarSecondaryButtonState.enabled,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = _palette(state);

    final button = Container(
      height: HaffarMetrics.buttonHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: HaffarTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: p.text,
            ),
          ),
        ],
      ),
    );

    if (onPressed != null && state != HaffarSecondaryButtonState.disabled) {
      return GestureDetector(onTap: onPressed, child: button);
    }
    return button;
  }
}

class _Palette {
  final Color background;
  final Color border;
  final Color text;
  final Color iconColor;

  const _Palette({
    required this.background,
    required this.border,
    required this.text,
    required this.iconColor,
  });
}

const _outlineOrange = Color(0xFFFD7202);
const _outlineGrey = HaffarColors.grey6;
const _inactiveText = HaffarColors.grey2;
const _inactiveIcon = Color(0xFF8F8F8F);

_Palette _palette(HaffarSecondaryButtonState state) {
  switch (state) {
    case HaffarSecondaryButtonState.enabled:
      return _Palette(
        background: Colors.white,
        border: _outlineOrange,
        text: _outlineOrange,
        iconColor: _outlineOrange,
      );
    case HaffarSecondaryButtonState.pressed:
      return _Palette(
        background: Colors.white,
        border: _outlineOrange,
        text: _outlineOrange,
        iconColor: _outlineOrange,
      );
    case HaffarSecondaryButtonState.disabled:
      return _Palette(
        background: Colors.white,
        border: _outlineGrey,
        text: _inactiveText,
        iconColor: _inactiveIcon,
      );
  }
}
