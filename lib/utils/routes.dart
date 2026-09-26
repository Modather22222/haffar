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
  static const units = '/units';
  static const lessonDetail = '/lesson-detail';
  static const unitExercise = '/unit-exercise';
  static const practiceQuiz = '/practice-quiz';
  static const publicProfile = '/public-profile';
  static const onboardingTwo = '/onboarding/two';
  static const onboardingThree = '/onboarding/three';
  static const onboardingFour = '/onboarding/four';
  static const onboardingFive = '/onboarding/five';
  static const onboardingSix = '/onboarding/six';
  static const onboardingSeven = '/onboarding/seven';
  static const onboardingEight = '/onboarding/eight';
  static const onboardingNine = '/onboarding/nine';
  static const onboardingTen = '/onboarding/ten';
  static const onboardingTwelve = '/onboarding/twelve';
  static const onboardingThirteen = '/onboarding/thirteen';
  static const onboardingFourteen = '/onboarding/fourteen';
  static const onboardingFifteen = '/onboarding/fifteen';
  static const signIn = '/sign-in';
  static const subscription = '/subscription';
  static const admin = '/admin';
  static const adminUser = '/admin/user';
  static const adminSubscriptions = '/admin/subscriptions';
  static const adminQuestions = '/admin/questions';
  static const adminContentEditor = '/admin/content/editor';
  static const adminContentUnits = '/admin/content/editor/units';
  static const adminContentLesson = '/admin/content/editor/lesson';
  static const adminContentQuestions = '/admin/content/editor/questions';
  static const adminContentQuestion = '/admin/content/editor/question';
}

/// Typed arguments for the /question route
class QuestionRouteArgs {
  final String subjectId;
  final int lessonIndex;
  final int questionIndex;

  const QuestionRouteArgs({
    required this.subjectId,
    required this.lessonIndex,
    required this.questionIndex,
  });
}

/// Typed arguments for the /feedback route
class FeedbackRouteArgs {
  final bool correct;
  final String? correctAnswer;
  final QuestionRouteArgs? questionArgs;

  const FeedbackRouteArgs({
    required this.correct,
    this.correctAnswer,
    this.questionArgs,
  });
}
