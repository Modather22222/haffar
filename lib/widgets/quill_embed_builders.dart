import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown_quill/markdown_quill.dart';

import '../design_system/colors.dart';
import 'markdown_text.dart';

/// Renders the `x-embed-table` block (a stored GFM table) as a read-only
/// preview inside the lesson editor. Quill ships no table embed rendering —
/// without a registered builder `_getEmbedBuilder` throws
/// `UnimplementedError` while building `TextLine`, which collapses the
/// editor into an error widget.
class QuillTableEmbedBuilder extends EmbedBuilder {
  const QuillTableEmbedBuilder();

  @override
  String get key => EmbeddableTable.tableType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    return MarkdownText(data is String ? data : '');
  }
}

/// Safety net for any embed type without a dedicated builder: renders a
/// small placeholder instead of letting `_getEmbedBuilder` throw and crash
/// the editor.
class QuillUnknownEmbedBuilder extends EmbedBuilder {
  const QuillUnknownEmbedBuilder();

  /// Never matched by key — this builder is returned directly as the
  /// fallback in `QuillEditorConfig.unknownEmbedBuilder`.
  @override
  String get key => 'x-embed-unknown';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: HaffarColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HaffarColors.outline.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attachment_outlined, size: 16, color: HaffarColors.grey3),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'محتوى مرفق غير معروض',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                color: HaffarColors.grey3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
