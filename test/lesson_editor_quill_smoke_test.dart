import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lesson quill editor subtree builds without errors', (
    tester,
  ) async {
    final controller = QuillController.basic();
    controller.document = Document()..insert(0, 'ملخص الدرس التجريبي');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar', 'SA')],
        locale: const Locale('ar', 'SA'),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('إدراج صورة'),
                      ),
                      const Spacer(),
                      TextButton(onPressed: () {}, child: const Text('معاينة')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: QuillSimpleToolbar(
                            controller: controller,
                            config: const QuillSimpleToolbarConfig(
                              showAlignmentButtons: true,
                              showDirection: true,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        QuillEditor.basic(
                          controller: controller,
                          config: QuillEditorConfig(
                            placeholder: 'اكتب ملخص الدرس هنا...',
                            padding: const EdgeInsets.all(12),
                            minHeight: 200,
                            embedBuilders: [
                              QuillEditorImageEmbedBuilder(
                                config: const QuillEditorImageEmbedConfig(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final error = tester.takeException();
    if (error != null) {
      // ignore: avoid_print
      print('CAUGHT: $error');
    }
    expect(error, isNull);
  });
}
