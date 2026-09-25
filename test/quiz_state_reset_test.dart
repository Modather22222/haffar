import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/models/question.dart';
import 'package:haffar/providers/economy_provider.dart';
import 'package:haffar/screens/practice_quiz_screen.dart';
import 'package:haffar/widgets/question_widgets/question_widget_factory.dart';
import 'package:provider/provider.dart';

const _mcQ1 = Question(
  id: 'mc-1',
  subjectId: 'math',
  lessonIndex: 0,
  type: QuestionType.multipleChoice,
  text: 'ما هو 1 + 1؟',
  options: ['1', '2', '3'],
  correctIndex: 1,
);

const _mcQ2 = Question(
  id: 'mc-2',
  subjectId: 'math',
  lessonIndex: 0,
  type: QuestionType.multipleChoice,
  text: 'ما هو 2 + 2؟',
  options: ['3', '4', '5'],
  correctIndex: 1,
);

const _fillQ1 = Question(
  id: 'fill-1',
  subjectId: 'math',
  lessonIndex: 0,
  type: QuestionType.fillBlank,
  text: 'أكمل: 7 + 8 =',
  correctWords: ['15'],
);

const _fillQ2 = Question(
  id: 'fill-2',
  subjectId: 'math',
  lessonIndex: 0,
  type: QuestionType.fillBlank,
  text: 'أكمل: 9 + 6 =',
  correctWords: ['15'],
);

Future<void> _pumpQuiz(WidgetTester tester, List<Question> questions) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<EconomyProvider>(
        create: (_) => EconomyProvider(),
        child: PracticeQuizScreen(
          subjectId: 'math',
          title: 'رياضيات',
          questions: questions,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _checkEnabled(WidgetTester tester) {
  final btn = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'تحقق'),
  );
  return btn.onPressed != null;
}

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(find.text('متابعة'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('multiple-choice selection does not carry to the next question', (
    tester,
  ) async {
    await _pumpQuiz(tester, const [_mcQ1, _mcQ2]);
    expect(find.text('ما هو 1 + 1؟'), findsOneWidget);

    // Answer Q1 and continue.
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(_checkEnabled(tester), isTrue);
    await tester.tap(find.widgetWithText(ElevatedButton, 'تحقق'));
    await tester.pumpAndSettle();
    await _continue(tester);

    // Q2 must show fresh state: no selection → check disabled.
    expect(find.text('ما هو 2 + 2؟'), findsOneWidget);
    expect(
      _checkEnabled(tester),
      isFalse,
      reason: 'Q2 starts with a selection carried over from Q1',
    );
  });

  testWidgets('fill-blank text does not carry to the next question', (
    tester,
  ) async {
    await _pumpQuiz(tester, const [_fillQ1, _fillQ2]);
    expect(find.text('أكمل: 7 + 8 ='), findsOneWidget);

    // Answer Q1 and continue.
    await tester.enterText(find.byType(TextField), '15');
    await tester.pumpAndSettle();
    expect(_checkEnabled(tester), isTrue);
    await tester.tap(find.widgetWithText(ElevatedButton, 'تحقق'));
    await tester.pumpAndSettle();
    await _continue(tester);

    // Q2 must start empty, enabled, and submittable.
    expect(find.text('أكمل: 9 + 6 ='), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.controller?.text ?? '',
      isEmpty,
      reason: 'Q2 input still holds Q1 text',
    );
    expect(field.enabled, isTrue, reason: 'Q2 input is stuck disabled');
    expect(
      _checkEnabled(tester),
      isFalse,
      reason: 'Q2 check button stuck from Q1 submission',
    );

    // The user can actually answer and continue.
    await tester.enterText(find.byType(TextField), '15');
    await tester.pumpAndSettle();
    expect(_checkEnabled(tester), isTrue);
    await tester.tap(find.widgetWithText(ElevatedButton, 'تحقق'));
    await tester.pumpAndSettle();
    expect(find.text('أحسنت! إجابة صحيحة'), findsOneWidget);
  });

  Widget unkeyedHarness(Question q) {
    return MaterialApp(
      home: Scaffold(
        body: QuestionWidgetFactory.create(
          question: q,
          subjectName: 'math',
          lessonNumber: 1,
          onBack: () {},
          onSkip: () {},
          onNext: () {},
          onSubmitAnswer: (_, _) {},
        ),
      ),
    );
  }

  testWidgets(
    'unkeyed caller: fill-blank text resets when rebuilt with a new question',
    (tester) async {
      await tester.pumpWidget(unkeyedHarness(_fillQ1));
      await tester.enterText(find.byType(TextField), '15');
      await tester.pumpAndSettle();

      await tester.pumpWidget(unkeyedHarness(_fillQ2));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(
        field.controller?.text ?? '',
        isEmpty,
        reason: 'unkeyed rebuild kept Q1 text in Q2',
      );
      expect(field.enabled, isTrue, reason: 'Q2 input stuck disabled');
    },
  );

  testWidgets(
    'unkeyed caller: MC selection resets when rebuilt with a new question',
    (tester) async {
      await tester.pumpWidget(unkeyedHarness(_mcQ1));
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(_checkEnabled(tester), isTrue);

      await tester.pumpWidget(unkeyedHarness(_mcQ2));
      await tester.pumpAndSettle();

      expect(
        _checkEnabled(tester),
        isFalse,
        reason: 'Q2 starts with Q1 selection carried over',
      );
    },
  );
}
