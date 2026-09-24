import '../design_system/colors.dart';
import 'package:flutter/material.dart';

/// Selectable word-bank chip — shows grey when moved
class WordBankChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const WordBankChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<WordBankChip> createState() => _WordBankChipState();
}

class _WordBankChipState extends State<WordBankChip> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? HaffarColors.surfaceHigh
              : widget.onTap != null
              ? Colors.white
              : HaffarColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? HaffarColors.outline.withValues(alpha: 0.2)
                : widget.onTap != null
                ? HaffarColors.primary.withValues(alpha: 0.5)
                : HaffarColors.outline.withValues(alpha: 0.2),
            width: widget.onTap != null ? 1.5 : 1,
          ),
          boxShadow: widget.onTap != null && !widget.isSelected
              ? [
                  BoxShadow(
                    color: HaffarColors.primary.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: widget.isSelected
                ? HaffarColors.textSecondary
                : HaffarColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
