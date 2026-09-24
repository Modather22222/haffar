import 'package:flutter/material.dart';
import '../../models/question.dart';
import 'multiple_choice_question.dart';
import 'true_false_question.dart';
import 'fill_blank_question.dart';
import 'matching_question.dart';
import 'definition_question.dart';
import 'ordering_question.dart';
import 'reading_question.dart';
import 'calculation_question.dart';
import 'explanation_question.dart';
import 'diagram_question.dart';
import 'classification_question.dart';

class QuestionWidgetFactory {
  QuestionWidgetFactory._();

  static Widget create({
    required Question question,
    required String subjectName,
    required int lessonNumber,
    String? customTitle,
    required VoidCallback onBack,
    required VoidCallback onSkip,
    required VoidCallback onNext,
    required void Function(bool, String?) onSubmitAnswer,
    bool locked = false,
  }) {
    final pathTitle = customTitle ?? '$subjectName - درس $lessonNumber';

    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceQuestion(
          pathTitle: pathTitle,
          questionText: question.text,
          hint: question.hint,
          options: question.options,
          correctIndex: question.correctIndex,
          xpReward: question.xpReward,
          onBack: onBack,
          onSkip: onSkip,
          onNext: onNext,
          onSubmitAnswer: onSubmitAnswer,
          locked: locked,
        );
      case QuestionType.trueFalse:
        return TrueFalseQuestion(
          pathTitle: pathTitle,
          questionText: question.text,
          xpReward: question.xpReward,
          correctAnswer: question.correctIndex == 0,
          onBack: onBack,
          onSkip: onSkip,
          onNext: onNext,
          onSubmitAnswer: onSubmitAnswer,
          locked: locked,
        );
      case QuestionType.fillBlank:
        return FillBlankQuestion(
          pathTitle: pathTitle,
          questionText: question.text,
          info: question.hint,
          correctWords: question.correctWords ?? [],
          xpReward: question.xpReward,
          onBack: onBack,
          onSkip: onSkip,
          onNext: onNext,
          onSubmitAnswer: onSubmitAnswer,
          locked: locked,
        );
      case QuestionType.matching:
        final opts = question.options;
        final half = opts.length ~/ 2;
        return MatchingQuestion(
          pathTitle: pathTitle,
          questionText: question.text,
          leftItems: opts.take(half).toList(),
          rightItems: opts.skip(half).take(half).toList(),
          xpReward: question.xpReward,
          onBack: onBack,
          onSkip: onSkip,
          onNext: onNext,
          onSubmitAnswer: onSubmitAnswer,
          locked: locked,
        );
      case QuestionType.definition:
        return DefinitionQuestion(
          pathTitle: pathTitle,
          term: question.text,
          questionText: 'اختر التعريف الصحيح للمصطلح التالي:',
          options: question.options,
          correctIndex: question.correctIndex,
          xpReward: question.xpReward,
          onBack: onBack,
          onSkip: onSkip,
          onNext: onNext,
          onSubmitAnswer: onSubmitAnswer,
          locked: locked,
        );
      case QuestionType.ordering:
        return OrderingQuestion(
          pathTitle: pathTitle,
          questionText: question.text,
          options: question.options,
          correctOrder: question.correctWords ?? question.options,
          xpReward: question.xpReward,
          onBack: onBack,
          onSkip: onSkip,
          onNext: onNext,
          onSubmitAnswer: onSubmitAnswer,
          locked: locked,
        );
      case QuestionType.reading:
        return ReadingQuestion(
          pathTitle: pathTitle,
          passage: question.passage ?? question.text,
          questionText: question.text,
          options: question.options,
          correctIndex: question.correctIndex,
          xpReward: question.xpReward,
          onBack: onBack,
          onSkip: onSkip,
          onNext: onNext,
          onSubmitAnswer: onSubmitAnswer,
          locked: locked,
        );
      case QuestionType.calculation:
        return CalculationQuestion(
          pathTitle: pathTitle,
          questionText: question.text,
          hint: question.hint,
          formula: question.passage,
          options: question.options,
          correctWords: question.correctWords ?? [],
          correctIndex: question.correctIndex,
          xpReward: question.xpReward,
          onBack: onBack,
          onSkip: onSkip,
          onNext: onNext,
          onSubmitAnswer: onSubmitAnswer,
          locked: locked,
        );
      case QuestionType.diagram:
        return DiagramQuestion(
          pathTitle: pathTitle,
          questionText: question.text,
          imageUrl: question.imageUrl ?? '',
          options: question.options,
          correctIndex: question.correctIndex,
          xpReward: question.xpReward,
          onBack: onBack,
          onSkip: onSkip,
          onNext: onNext,
          onSubmitAnswer: onSubmitAnswer,
          locked: locked,
        );
      case QuestionType.classification:
        return ClassificationQuestion(
          pathTitle: pathTitle,
          questionText: question.text,
          items: question.options,
          itemCategories: question.itemCategories ?? [],
          xpReward: question.xpReward,
          onBack: onBack,
          onSkip: onSkip,
          onNext: onNext,
          onSubmitAnswer: onSubmitAnswer,
          locked: locked,
        );
      case QuestionType.explanation:
      case QuestionType.composition:
        return ExplanationQuestion(
          pathTitle: pathTitle,
          questionText: question.text,
          passage: question.passage,
          xpReward: question.xpReward,
          onBack: onBack,
          onSkip: onSkip,
          onNext: onNext,
          onSubmitAnswer: onSubmitAnswer,
          locked: locked,
        );
    }
  }
}
