import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../../colors.dart';

/// Haffar list row — selectable full-width row with optional leading icon.
/// White with inner grey border, 12px radius, dark text.
enum HaffarListRowState { enabled, pressed, disabled }

class HaffarListRow extends StatelessWidget {
  final HaffarListRowState state;
  final String label;
  final String? value;
  final Widget? leading;
  final bool selected;
  final double? width;
  final VoidCallback? onPressed;

  const HaffarListRow({
    super.key,
    this.state = HaffarListRowState.enabled,
    required this.label,
    this.value,
    this.leading,
    this.selected = false,
    this.width,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = _palette(state, selected);

    final row = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border, width: 2),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: HaffarTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: TextStyle(
                fontFamily: HaffarTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: p.text,
              ),
            ),
        ],
      ),
    );

    if (onPressed != null && state != HaffarListRowState.disabled) {
      return GestureDetector(onTap: onPressed, child: row);
    }
    return row;
  }
}

class _Palette {
  final Color background;
  final Color border;
  final Color text;

  const _Palette({
    required this.background,
    required this.border,
    required this.text,
  });
}

const _darkText = HaffarColors.grey1;
const _chipBorder = Color(0xFFD0D0D0);
const _selectedBorder = HaffarColors.primary;
const _inactiveText = HaffarColors.grey2;

_Palette _palette(HaffarListRowState state, bool selected) {
  switch (state) {
    case HaffarListRowState.enabled:
      return _Palette(
        background: Colors.white,
        border: selected ? _selectedBorder : _chipBorder,
        text: _darkText,
      );
    case HaffarListRowState.pressed:
      return _Palette(
        background: Colors.white,
        border: selected ? _selectedBorder : _chipBorder,
        text: _darkText,
      );
    case HaffarListRowState.disabled:
      return _Palette(
        background: Colors.white,
        border: _chipBorder,
        text: _inactiveText,
      );
  }
}
