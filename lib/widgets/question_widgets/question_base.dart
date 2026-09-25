import '../../design_system/colors.dart';
import 'package:flutter/material.dart';
import '../markdown_text.dart';
import 'question_header.dart';

/// Base widget shared by ALL question types.
/// Stateless — each subclass manages its own answer state and renders inline feedback.
class QuestionBase extends StatelessWidget {
  final String pathTitle;
  final String questionText;
  final String? hint;
  final String? info;
  final String? imageUrl;
  final int xpReward;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final WidgetBuilder buildBody;

  const QuestionBase({
    super.key,
    required this.pathTitle,
    required this.questionText,
    this.hint,
    this.info,
    this.imageUrl,
    required this.xpReward,
    required this.onBack,
    required this.onSkip,
    required this.buildBody,
  });

  @override
  Widget build(BuildContext context) {
    // NOTE: no top bar here — the quiz screen renders the shared LearnTopBar
    // (close + progress + hearts) above the question content.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MarkdownText(
              questionText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: HaffarColors.textPrimary,
              ),
            ),
          ),
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _QuestionImage(url: imageUrl!),
            ),
          ],
          const SizedBox(height: 20),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: HintCard(text: hint!),
            ),
          if (hint != null) const SizedBox(height: 20),
          if (info != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InfoCard(text: info!),
            ),
          if (info != null) const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: buildBody(context),
          ),
        ],
      ),
    );
  }
}

class _QuestionImage extends StatelessWidget {
  const _QuestionImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Container(
            padding: const EdgeInsets.all(12),
            color: HaffarColors.surfaceHigh,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 18,
                  color: HaffarColors.grey3,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'تعذّر تحميل الصورة',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      color: HaffarColors.grey3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
