import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/widgets/question_widgets/ordering_question.dart';

Widget _wrap(OrderingQuestion q, {required bool rtl}) {
  return MaterialApp(
    home: Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(body: SingleChildScrollView(child: q)),
    ),
  );
}

OrderingQuestion _question() {
  return const OrderingQuestion(
    pathTitle: 't',
    questionText: 'رتّب',
    options: ['A', 'B', 'C'],
    correctOrder: ['A', 'B', 'C'],
    xpReward: 5,
    onBack: _noop,
    onSkip: _noop,
    onNext: _noop,
    onSubmitAnswer: _ignore,
  );
}

Future<void> _dragItem(
  WidgetTester tester,
  Finder item,
  Offset offset, {
  required String label,
}) async {
  final center = tester.getCenter(item);
  final gesture = await tester.startGesture(center);
  await tester.pump(const Duration(milliseconds: 600)); // long-press timeout
  const steps = 10.0;
  for (var i = 1; i <= steps; i++) {
    await gesture.moveBy(offset / steps);
    await tester.pump(const Duration(milliseconds: 32));
  }
  await tester.pumpAndSettle();
  await gesture.up();
  await tester.pumpAndSettle();
  expect(find.byType(OrderingQuestion), findsOneWidget, reason: label);
}

List<String> _lettersIn(WidgetTester tester) {
  return tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(OrderingQuestion),
          matching: find.byType(Text),
        ),
      )
      .map((t) => t.data ?? '')
      .where((t) => t == 'A' || t == 'B' || t == 'C')
      .toList();
}

void main() {
  for (final rtl in [true, false]) {
    final dir = rtl ? 'RTL' : 'LTR';

    testWidgets('$dir: dragging bottom item to the top sticks', (tester) async {
      await tester.pumpWidget(_wrap(_question(), rtl: rtl));
      await tester.pumpAndSettle();

      final aTop = tester.getTopLeft(find.text('A')).dy;
      final cCenter = tester.getCenter(find.text('C')).dy;
      await _dragItem(
        tester,
        find.text('C'),
        Offset(0, aTop - cCenter + 40),
        label: 'C did not move up',
      );

      final texts = _lettersIn(tester);
      expect(
        texts.indexOf('C'),
        lessThan(texts.indexOf('A')),
        reason: 'dragging C upward snapped back (order: $texts)',
      );
    });

    testWidgets('$dir: dragging top item to the bottom sticks', (tester) async {
      await tester.pumpWidget(_wrap(_question(), rtl: rtl));
      await tester.pumpAndSettle();

      final aCenter = tester.getCenter(find.text('A')).dy;
      final cBottom = tester.getBottomLeft(find.text('C')).dy;
      await _dragItem(
        tester,
        find.text('A'),
        Offset(0, cBottom - aCenter + 40),
        label: 'A did not move down',
      );

      final texts = _lettersIn(tester);
      expect(
        texts.indexOf('A'),
        greaterThan(texts.indexOf('B')),
        reason: 'dragging A downward did not stick (order: $texts)',
      );
      expect(
        texts.last,
        'A',
        reason: 'A should end up last after a full down-drag (order: $texts)',
      );
    });

    testWidgets('$dir: up-drag released above the list still reorders', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_question(), rtl: rtl));
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('C')),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveBy(const Offset(0, -320));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      final texts = _lettersIn(tester);
      expect(
        texts.indexOf('C'),
        lessThan(texts.indexOf('A')),
        reason:
            'up-drag released outside the list snapped back (order: $texts)',
      );
    });
  }
}

void _noop() {}
void _ignore(bool _, String? _) {}
