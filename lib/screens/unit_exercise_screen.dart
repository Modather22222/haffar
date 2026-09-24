import '../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../models/question.dart';
import '../models/unit.dart';
import '../services/lesson_unlocks.dart';
import '../utils/routes.dart';
import '../widgets/mascot.dart';
import '../widgets/xp_icon.dart';
import '../utils/game_constants.dart';

/// Full-screen "تمرين الوحدة" — opens after all lessons of the unit are done.
class UnitExerciseScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final int unitIndex;

  const UnitExerciseScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.unitIndex,
  });

  @override
  State<UnitExerciseScreen> createState() => _UnitExerciseScreenState();
}

class _UnitExerciseScreenState extends State<UnitExerciseScreen> {
  late final List<Question> _questions;

  @override
  void initState() {
    super.initState();
    final content = context.read<ContentProvider>();
    // Unit uses a private 5-heart pool per attempt — never global hearts.
    final pool = content.getUnitQuestions(widget.subjectId, widget.unitIndex);
    _questions = buildUnitQuiz(
      subjectId: widget.subjectId,
      unitIndex: widget.unitIndex,
      pool: pool,
      count: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    return Scaffold(
      backgroundColor: HaffarColors.bgPage,
      appBar: AppBar(
        title: Text(
          'تمرين الوحدة ${Unit.toArabicNumeral(widget.unitIndex + 1)}',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: HaffarColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: HaffarColors.primary,
                          width: 3,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: const Mascot(pose: MascotPose.celebrate, size: 96),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'تمرين الوحدة ${Unit.toArabicNumeral(widget.unitIndex + 1)}',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: HaffarColors.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'أكملت جميع دروس هذه الوحدة! اختبر معلوماتك في تمرين شامل يغطي كل ما تعلمته.',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 15,
                    height: 1.7,
                    color: HaffarColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: HaffarColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.favorite, size: 22, color: HaffarColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'كل محاولة ليها 5 قلوب خاصة — كل غلط هيخسرك قلب، لو خلصوا ترجع وتبدأ من جديد',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 14,
                          height: 1.6,
                          color: HaffarColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statCard(
                    const Icon(
                      Icons.quiz,
                      size: 22,
                      color: HaffarColors.primary,
                    ),
                    '${questions.length}',
                    'سؤالاً',
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    Image.asset(
                      'assets/icons/lesson.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                    '٣',
                    'دروس',
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    const XpIcon(size: 22),
                    '+${GameConstants.unitXpBase}',
                    '',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 56,
                child: Builder(
                  builder: (btnCtx) {
                    // Private 5-heart pool — never gated on global hearts.
                    final canStart = questions.isNotEmpty;
                    return ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canStart
                            ? HaffarColors.primary
                            : HaffarColors.grey3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: canStart
                          ? () => btnCtx.push(
                              '${Routes.practiceQuiz}?'
                              'subject=${Uri.encodeComponent(widget.subjectId)}'
                              '&title=${Uri.encodeComponent('${widget.subjectName} - تمرين الوحدة '
                              '${Unit.toArabicNumeral(widget.unitIndex + 1)}')}'
                              '&kind=unit&ref=${widget.unitIndex}',
                              extra: questions,
                            )
                          : null,
                      icon: const Icon(Icons.play_arrow, size: 26),
                      label: const Text(
                        'ابدأ تمرين الوحدة',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(Widget icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: HaffarColors.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (label.isNotEmpty)
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12,
                  color: HaffarColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
