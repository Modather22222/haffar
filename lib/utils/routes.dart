/// Shared route constants — import anywhere you need navigation paths
abstract class Routes {
  Routes._();
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const notification = '/notification';
  static const learningGoal = '/learning-goal';
  static const home = '/home';
  static const subjectSelect = '/subject-select';
  static const lessonPath = '/lesson-path';
  static const question = '/question';
  static const feedback = '/feedback';
  static const leaderboard = '/leaderboard';
  static const achievements = '/achievements';
  static const profile = '/profile';
  static const settings = '/settings';
  static const signingIn = '/signing-in';
}

/// Typed arguments for the /question route
class QuestionRouteArgs {
  final String subjectId;
  final int lessonIndex;
  final int questionIndex;

  const QuestionRouteArgs({required this.subjectId, required this.lessonIndex, required this.questionIndex});
}

/// Typed arguments for the /feedback route
class FeedbackRouteArgs {
  final bool correct;
  final String? correctAnswer;
  final QuestionRouteArgs? questionArgs;

  const FeedbackRouteArgs({required this.correct, this.correctAnswer, this.questionArgs});
}
