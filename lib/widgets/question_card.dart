import '../design_system/colors.dart';
import 'package:flutter/material.dart';

/// Reusable question card with multiple-choice options
class QuestionCard extends StatelessWidget {
  final String question;
  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int>? onOptionSelected;

  const QuestionCard({
    super.key,
    required this.question,
    required this.options,
    this.selectedIndex,
    this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: HaffarColors.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            question,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        ...options.asMap().entries.map((entry) {
          final idx = entry.key;
          final opt = entry.value;
          final isSelected = selectedIndex == idx;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onOptionSelected?.call(idx),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? HaffarColors.primary.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? HaffarColors.primary
                        : HaffarColors.outline.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? []
                      : [
                          BoxShadow(
                            color: HaffarColors.outline.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? HaffarColors.primary
                            : HaffarColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
