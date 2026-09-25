import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/widgets/question_widgets/question_base.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  QuestionBase build({String text = 'سؤال عادي', String? imageUrl}) =>
      QuestionBase(
        pathTitle: 'علوم - درس 1',
        questionText: text,
        imageUrl: imageUrl,
        xpReward: 5,
        onBack: () {},
        onSkip: () {},
        buildBody: (_) => const SizedBox(),
      );

  testWidgets('renders question text as markdown', (tester) async {
    await tester.pumpWidget(wrap(build(text: 'اختر **الصحيح** من الخيارات')));
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('الصحيح'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the image banner only when imageUrl is set', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(build()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);

    await tester.pumpWidget(
      wrap(build(imageUrl: 'https://example.com/chart.png')),
    );
    await tester.pumpAndSettle();
    // Widget tests have no network: the errorBuilder fallback proves the
    // banner rendered and failed gracefully.
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.text('تعذّر تحميل الصورة'), findsOneWidget);
  });
}
