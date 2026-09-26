import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/utils/rich_content.dart';
import 'package:haffar/widgets/quill_embed_builders.dart';

const _tableMarkdown =
    '| الجانب | الخيار الأول | الخيار الثاني |\n'
    '| --- | --- | --- |\n'
    '| الصف الأول | قيمة | قيمة |\n'
    '| الصف الثاني | قيمة | قيمة |';

void main() {
  testWidgets('inserting the comparison table block into the editor', (
    tester,
  ) async {
    final controller = QuillController.basic();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuillEditor.basic(
            controller: controller,
            config: QuillEditorConfig(
              embedBuilders: [
                QuillEditorImageEmbedBuilder(
                  config: const QuillEditorImageEmbedConfig(),
                ),
                const QuillTableEmbedBuilder(),
              ],
              unknownEmbedBuilder: const QuillUnknownEmbedBuilder(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    insertMarkdownAt(controller, _tableMarkdown);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('الجانب'), findsWidgets);
    expect(find.textContaining('الصف الأول'), findsWidgets);
  });
}
