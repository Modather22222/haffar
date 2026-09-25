import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/widgets/markdown_text.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('renders markdown content', (tester) async {
    await tester.pumpWidget(_wrap(const MarkdownText('نص **مهم** هنا')));
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders network images through the image builder', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const MarkdownText('![](https://example.com/a.png)')),
    );
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty input renders an empty box', (tester) async {
    await tester.pumpWidget(_wrap(const MarkdownText('   ')));
    expect(find.byType(MarkdownBody), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('applies the provided text style', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const MarkdownText(
          'نص',
          style: TextStyle(fontSize: 20, fontFamily: 'BeVietnamPro'),
        ),
      ),
    );
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
