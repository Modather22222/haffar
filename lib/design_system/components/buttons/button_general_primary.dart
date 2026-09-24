import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../../colors.dart';

enum HaffarPrimaryButtonState { enabled, pressed, disabled }

class HaffarPrimaryButton extends StatelessWidget {
  final HaffarPrimaryButtonState state;
  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final Color? backgroundColor;

  const HaffarPrimaryButton({
    super.key,
    this.state = HaffarPrimaryButtonState.enabled,
    required this.label,
    this.onPressed,
    this.fullWidth = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = _palette(state);
    final bg = backgroundColor ?? p.background;

    final button = Container(
      width: fullWidth ? double.infinity : null,
      height: HaffarMetrics.buttonHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(HaffarMetrics.radiusSm),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
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

    if (onPressed != null && state != HaffarPrimaryButtonState.disabled) {
      return GestureDetector(onTap: onPressed, child: button);
    }
    return button;
  }
}

class _Palette {
  final Color background;
  final Color text;
  final Color iconColor;

  const _Palette({
    required this.background,
    required this.text,
    required this.iconColor,
  });
}

const _primaryOrange = Color(0xFFFD7202);
const _inactiveBg = HaffarColors.grey6;
const _inactiveText = HaffarColors.grey2;
const _inactiveIcon = Color(0xFF8F8F8F);

_Palette _palette(HaffarPrimaryButtonState state) {
  switch (state) {
    case HaffarPrimaryButtonState.enabled:
      return _Palette(
        background: _primaryOrange,
        text: Colors.white,
        iconColor: Colors.white,
      );
    case HaffarPrimaryButtonState.pressed:
      return _Palette(
        background: _primaryOrange,
        text: Colors.white,
        iconColor: Colors.white,
      );
    case HaffarPrimaryButtonState.disabled:
      return _Palette(
        background: _inactiveBg,
        text: _inactiveText,
        iconColor: _inactiveIcon,
      );
  }
}
