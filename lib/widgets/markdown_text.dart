import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../design_system/colors.dart';

/// Renders stored GitHub-Flavored Markdown inline (lesson summaries, key
/// points, question text/passages/hints). Falls back to an empty box for
/// blank input and inherits the ambient [Directionality] (the app runs RTL).
class MarkdownText extends StatelessWidget {
  const MarkdownText(this.data, {super.key, this.style, this.textAlign});

  final String data;
  final TextStyle? style;

  /// Block alignment for paragraphs/headings (defaults to start, which is
  /// right in the app's RTL locale).
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (data.trim().isEmpty) return const SizedBox.shrink();
    final base =
        style ??
        const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 14,
          color: HaffarColors.textSecondary,
          height: 1.6,
        );
    final align = switch (textAlign) {
      TextAlign.center => WrapAlignment.center,
      TextAlign.end || TextAlign.right => WrapAlignment.end,
      _ => WrapAlignment.start,
    };
    return MarkdownBody(
      data: data,
      softLineBreak: true,
      styleSheet: _styleSheet(base, align),
      imageBuilder: _imageBuilder,
    );
  }

  static MarkdownStyleSheet _styleSheet(TextStyle base, WrapAlignment align) {
    final fs = base.fontSize ?? 14;
    return MarkdownStyleSheet(
      textAlign: align,
      h1Align: align,
      h2Align: align,
      h3Align: align,
      h4Align: align,
      h5Align: align,
      h6Align: align,
      p: base,
      pPadding: EdgeInsets.zero,
      blockSpacing: 6,
      h1: base.copyWith(
        fontSize: fs * 1.5,
        fontWeight: FontWeight.w800,
        height: 1.3,
      ),
      h2: base.copyWith(
        fontSize: fs * 1.35,
        fontWeight: FontWeight.w800,
        height: 1.3,
      ),
      h3: base.copyWith(
        fontSize: fs * 1.2,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      h4: base.copyWith(fontSize: fs * 1.1, fontWeight: FontWeight.w700),
      h5: base.copyWith(fontSize: fs * 1.05, fontWeight: FontWeight.w700),
      h6: base.copyWith(fontSize: fs, fontWeight: FontWeight.w700),
      h1Padding: EdgeInsets.zero,
      h2Padding: EdgeInsets.zero,
      h3Padding: EdgeInsets.zero,
      h4Padding: EdgeInsets.zero,
      h5Padding: EdgeInsets.zero,
      h6Padding: EdgeInsets.zero,
      strong: base.copyWith(fontWeight: FontWeight.w700),
      em: base.copyWith(fontStyle: FontStyle.italic),
      del: base.copyWith(decoration: TextDecoration.lineThrough),
      code: base.copyWith(
        fontFamily: 'Courier',
        backgroundColor: HaffarColors.surfaceHigh,
      ),
      blockquote: base.copyWith(
        color:
            base.color?.withValues(alpha: 0.85) ?? HaffarColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
      blockquotePadding: const EdgeInsets.all(8),
      blockquoteDecoration: BoxDecoration(
        color: HaffarColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      listIndent: 22,
      a: base.copyWith(
        color: HaffarColors.primaryDark,
        decoration: TextDecoration.underline,
      ),
      img: base.copyWith(color: HaffarColors.grey3),
    );
  }

  static Widget _imageBuilder(Uri uri, String? alt, String? title) {
    final url = uri.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Container(
            padding: const EdgeInsets.all(12),
            color: HaffarColors.surfaceHigh,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.broken_image_outlined,
                  size: 18,
                  color: HaffarColors.grey3,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    alt ?? url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
