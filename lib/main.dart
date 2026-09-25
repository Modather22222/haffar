import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'design_system/colors.dart';
import 'providers/app_provider.dart';
import 'providers/content_provider.dart';
import 'providers/economy_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/session_provider.dart';
import 'utils/app_error.dart';
import 'utils/app_logger.dart';
import 'utils/app_toast.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_one_screen.dart';
import 'screens/sign_in_loading_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/learning_goal_screen.dart';
import 'screens/home_screen.dart';
import 'screens/subject_select_screen.dart';
import 'screens/lesson_path_screen.dart';
import 'screens/lesson_detail_screen.dart';
import 'screens/unit_exercise_screen.dart';
import 'screens/practice_quiz_screen.dart';
import 'screens/units_screen.dart';
import 'screens/public_profile_screen.dart';
import 'screens/question_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'services/push_service.dart';
import 'screens/onboarding_two_screen.dart';
import 'screens/onboarding_three_screen.dart';
import 'screens/onboarding_four_screen.dart';
import 'screens/onboarding_five_screen.dart';
import 'screens/onboarding_six_screen.dart';
import 'screens/onboarding_seven_screen.dart';
import 'screens/onboarding_eight_screen.dart';
import 'screens/onboarding_nine_screen.dart';
import 'screens/onboarding_ten_screen.dart';
import 'screens/onboarding_twelve_screen.dart';
import 'screens/onboarding_thirteen_screen.dart';
import 'screens/onboarding_fourteen_screen.dart';
import 'screens/onboarding_fifteen_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/admin/admin_shell_screen.dart';
import 'screens/admin/admin_user_detail_screen.dart';
import 'models/question.dart';
import 'models/subject.dart';
import 'utils/routes.dart';
import 'widgets/mascot.dart';

// Provided at build time: CI uses --dart-define; local runs may use
// --dart-define-from-file=env.json (see env.example.json, gitignored).
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLog.info('main() start');
  // In release mode an uncaught async error kills the app with no message.
  // Report instead of crashing so the user always sees a screen.
  FlutterError.onError = (details) {
    AppLog.error('FlutterError', details.exception, details.stack);
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.error('Uncaught async error', error, stack);
    return true;
  };
  // Log config shape only — never the key itself.
  AppLog.info(
    'supabase host=${Uri.tryParse(_supabaseUrl)?.host ?? '(bad-url)'} '
    'keyLen=${_supabaseAnonKey.length}',
  );
  Object? initError;
  try {
    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL / SUPABASE_ANON_KEY. '
        'Pass --dart-define or --dart-define-from-file=env.json',
      );
    }
    AppLog.info('Supabase.initialize start');
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabaseAnonKey,
    );
    AppLog.info('Supabase.initialize OK');
  } catch (e, st) {
    AppLog.error('Supabase.initialize FAILED', e, st);
    initError = e;
  }
  // Push is best-effort: logs on failure, never blocks startup.
  await PushService.instance.init();
  AppLog.info('runApp (initError=${initError != null})');
  runApp(HaffarApp(initError: initError));
}

class HaffarApp extends StatefulWidget {
  final Object? initError;

  const HaffarApp({super.key, this.initError});

  @override
  State<HaffarApp> createState() => _HaffarAppState();
}

class _HaffarAppState extends State<HaffarApp> {
  Object? _initError;
  bool _retrying = false;
  late final AppProvider _app;

  @override
  void initState() {
    super.initState();
    _initError = widget.initError;
    _app = AppProvider();
  }

  @override
  void dispose() {
    _app.dispose();
    super.dispose();
  }

  Future<void> _retryInit() async {
    setState(() => _retrying = true);
    try {
      if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
        throw StateError(
          'Missing SUPABASE_URL / SUPABASE_ANON_KEY. '
          'Pass --dart-define or --dart-define-from-file=env.json',
        );
      }
      await Supabase.initialize(
        url: _supabaseUrl,
        publishableKey: _supabaseAnonKey,
      );
      if (mounted) setState(() => _initError = null);
    } catch (e) {
      if (mounted) setState(() => _initError = e);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initError = _initError;
    return MultiProvider(
      providers: [
        // Facade for screens that need mixed concerns.
        ChangeNotifierProvider<AppProvider>.value(value: _app),
        // Narrow providers for fine-grained rebuilds (same instances).
        ChangeNotifierProvider<ContentProvider>.value(value: _app.content),
        ChangeNotifierProvider<EconomyProvider>.value(value: _app.economy),
        ChangeNotifierProvider<ProgressProvider>.value(value: _app.progress),
        ChangeNotifierProvider<SessionProvider>.value(value: _app.session),
      ],
      child: MaterialApp.router(
        title: 'حفار',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        locale: const Locale('ar', 'SA'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar', 'SA')],
        theme: HaffarTheme.lightTheme,
        routerConfig: initError == null
            ? router
            : GoRouter(
                initialLocation: '/',
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, _) => _InitErrorScreen(
                      error: initError,
                      retrying: _retrying,
                      onRetry: _retryInit,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Shown instead of the app when backend init fails — friendly Arabic copy
/// with a retry button. Raw exception stays in logs only.
class _InitErrorScreen extends StatelessWidget {
  final Object error;
  final bool retrying;
  final VoidCallback onRetry;

  const _InitErrorScreen({
    required this.error,
    required this.retrying,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final detail = AppError.userMessage(error, fallback: AppError.network);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 72,
                color: HaffarColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'تعذر الاتصال بالخادم',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 14,
                  color: HaffarColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: retrying ? null : onRetry,
                  child: Text(
                    retrying ? 'جارٍ المحاولة...' : 'إعادة المحاولة',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final GoRouter router = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
    GoRoute(
      path: Routes.welcome,
      builder: (_, _) => const OnboardingOneScreen(),
    ),
    GoRoute(
      path: Routes.onboardingTwo,
      builder: (_, _) => const OnboardingTwoScreen(),
    ),
    GoRoute(
      path: Routes.onboardingThree,
      builder: (_, _) => const OnboardingThreeScreen(),
    ),
    GoRoute(
      path: Routes.onboardingFour,
      builder: (_, _) => const OnboardingFourScreen(),
    ),
    GoRoute(
      path: Routes.onboardingFive,
      builder: (_, _) => const OnboardingFiveScreen(),
    ),
    GoRoute(
      path: Routes.onboardingSix,
      builder: (_, _) => const OnboardingSixScreen(),
    ),
    GoRoute(
      path: Routes.onboardingSeven,
      builder: (_, _) => const OnboardingSevenScreen(),
    ),
    GoRoute(
      path: Routes.onboardingEight,
      builder: (_, _) => const OnboardingEightScreen(),
    ),
    GoRoute(
      path: Routes.onboardingNine,
      builder: (_, _) => const OnboardingNineScreen(),
    ),
    GoRoute(
      path: Routes.onboardingTen,
      builder: (_, _) => const OnboardingTenScreen(),
    ),
    GoRoute(
      path: Routes.onboardingTwelve,
      builder: (_, _) => const OnboardingTwelveScreen(),
    ),
    GoRoute(
      path: Routes.onboardingThirteen,
      builder: (_, _) => const OnboardingThirteenScreen(),
    ),
    GoRoute(
      path: Routes.onboardingFourteen,
      builder: (_, _) => const OnboardingFourteenScreen(),
    ),
    GoRoute(
      path: Routes.onboardingFifteen,
      builder: (_, _) => const OnboardingFifteenScreen(),
    ),
    GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
    GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
    GoRoute(path: Routes.signup, builder: (_, _) => const SignupScreen()),
    GoRoute(
      path: Routes.notification,
      builder: (_, _) => const NotificationScreen(),
    ),
    GoRoute(
      path: Routes.learningGoal,
      builder: (_, _) => const LearningGoalScreen(),
    ),
    GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: Routes.subjectSelect,
      builder: (_, _) => const SubjectSelectScreen(),
    ),
    GoRoute(
      path: Routes.units,
      builder: (context, state) {
        final subjectId = state.uri.queryParameters['subject'] ?? '';
        final extraSubject = state.extra;
        final subject =
            (extraSubject is Subject ? extraSubject : null) ??
            context.read<ContentProvider>().subjectById(subjectId);
        if (subject == null) {
          return const Scaffold(body: SizedBox.shrink());
        }
        return UnitsScreen(subjectId: subjectId, subject: subject);
      },
    ),
    GoRoute(
      path: Routes.lessonPath,
      builder: (_, _) => const LessonPathScreen(),
    ),
    GoRoute(
      path: Routes.lessonDetail,
      builder: (context, state) {
        final subjectId = state.uri.queryParameters['subject'] ?? '';
        final lessonIndex =
            int.tryParse(state.uri.queryParameters['lesson'] ?? '0') ?? 0;
        return LessonDetailScreen(
          subjectId: subjectId,
          lessonIndex: lessonIndex,
        );
      },
    ),
    GoRoute(
      path: Routes.unitExercise,
      builder: (context, state) {
        final subjectId = state.uri.queryParameters['subject'] ?? '';
        final subjectName = state.uri.queryParameters['name'] ?? subjectId;
        final unitIndex =
            int.tryParse(state.uri.queryParameters['unit'] ?? '0') ?? 0;
        return UnitExerciseScreen(
          subjectId: subjectId,
          subjectName: subjectName,
          unitIndex: unitIndex,
        );
      },
    ),
    GoRoute(
      path: Routes.practiceQuiz,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        final subjectId = q['subject'] ?? '';
        final title = q['title'] ?? '';
        final kind = q['kind'] ?? 'lesson';
        final ref = int.tryParse(q['ref'] ?? '0') ?? 0;
        final questions = state.extra;
        final isUnit = kind == 'unit';
        return PracticeQuizScreen(
          subjectId: subjectId,
          title: title,
          questions: questions is List<Question>
              ? List<Question>.from(questions)
              : const [],
          attemptKind: kind,
          attemptRefIndex: ref,
          completionPose: isUnit ? MascotPose.celebrate : MascotPose.cheer,
          completionTitle: isUnit ? 'ممتاز!' : 'أحسنت يا حفار!',
          completionMessage: isUnit
              ? 'أكملت تمرين الوحدة بنجاح واجتزت تحديها بالكامل'
              : 'أكملت جميع أسئلة هذا الدرس بنجاح',
        );
      },
    ),
    GoRoute(path: Routes.question, builder: (_, _) => const QuestionScreen()),
    GoRoute(path: Routes.feedback, builder: (_, _) => const FeedbackScreen()),
    GoRoute(
      path: Routes.publicProfile,
      builder: (_, state) {
        final uid = state.uri.queryParameters['uid'] ?? '';
        final name = state.uri.queryParameters['name'];
        return PublicProfileScreen(userId: uid, fallbackName: name);
      },
    ),
    GoRoute(
      path: Routes.achievements,
      builder: (_, _) => const AchievementsScreen(),
    ),
    GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
    GoRoute(path: Routes.admin, builder: (_, _) => const AdminShellScreen()),
    GoRoute(
      path: Routes.adminUser,
      builder: (_, state) {
        final uid = state.uri.queryParameters['id'] ?? '';
        return AdminUserDetailScreen(userId: uid);
      },
    ),
    GoRoute(
      path: Routes.signingIn,
      builder: (_, _) => const SignInLoadingScreen(),
    ),
  ],
  errorBuilder: (_, state) =>
      _RouteErrorScreen(location: state.uri.toString(), error: state.error),
);

/// Friendly Arabic page for unmatched routes / router errors.
class _RouteErrorScreen extends StatelessWidget {
  final String location;
  final Object? error;

  const _RouteErrorScreen({required this.location, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('صفحة غير موجودة')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.explore_off_outlined,
                size: 72,
                color: HaffarColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'تعذر فتح هذه الصفحة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                location,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  color: HaffarColors.textSecondary,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  AppError.userMessage(error!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 14,
                    color: HaffarColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HaffarTheme {
  HaffarTheme._();
  static const _primary = Color(0xFFFD7202);
  static const _primaryDark = Color(0xFFDE5301);
  static const _secondary = Color(0xFF1cb0f6);
  static const _tertiary = Color(0xFFff9600);
  static const _error = Color(0xFFba1a1a);
  static const _background = Color(0xFFF8F8F8);
  static const _textPrimary = Color(0xFF4B4B4B);
  static const _outline = Color(0xFFD9D9D9);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _background,
    colorScheme: const ColorScheme.light(
      primary: _primary,
      onPrimary: Colors.white,
      secondary: _secondary,
      onSecondary: Colors.white,
      tertiary: _tertiary,
      onTertiary: Colors.white,
      error: _error,
      onError: Colors.white,
      surface: _background,
      onSurface: _textPrimary,
      outline: _outline,
    ),
    // BeVietnamPro is the only heavy face declared in pubspec.yaml;
    // DIN2014Rounded is not shipped — keep theme aligned with real fonts.
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.33,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.44,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
      ),
      labelLarge: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
        height: 1.29,
      ),
      labelMedium: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
        height: 1.33,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryDark,
        textStyle: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HaffarColors.grey6,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
