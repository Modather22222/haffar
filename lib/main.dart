import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'design_system/colors.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_one_screen.dart';
import 'screens/sign_in_loading_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/learning_goal_screen.dart';
import 'screens/home_screen.dart';
import 'screens/subject_select_screen.dart';
import 'screens/lesson_path_screen.dart';
import 'screens/question_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/routes.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://qfngbhrlqyojfwoadher.supabase.co');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_n-oS6tLxz4yi7k3_s21euQ_X0hQs8qK');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // In release mode an uncaught async error kills the app with no message.
  // Report instead of crashing so the user always sees a screen.
  FlutterError.onError = FlutterError.presentError;
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught async error: $error\n$stack');
    return true;
  };
  Object? initError;
  try {
    await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseAnonKey);
  } catch (e) {
    initError = e;
  }
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

  @override
  void initState() {
    super.initState();
    _initError = widget.initError;
  }

  Future<void> _retryInit() async {
    setState(() => _retrying = true);
    try {
      await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseAnonKey);
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
      providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
      child: MaterialApp.router(
        title: 'حفار',
        debugShowCheckedModeBanner: false,
        builder: (_, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
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

/// Shown instead of the app when backend init fails — displays the actual
/// error so a crash is never silent, with a retry button.
class _InitErrorScreen extends StatelessWidget {
  final Object error;
  final bool retrying;
  final VoidCallback onRetry;

  const _InitErrorScreen({required this.error, required this.retrying, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.cloud_off, size: 72, color: HaffarColors.primary),
              const SizedBox(height: 16),
              const Text(
                'تعذر الاتصال بالخادم',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'تحقق من الإنترنت ثم حاول مجدداً',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: HaffarColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HaffarColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  error.toString(),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: retrying ? null : onRetry,
                  child: Text(
                    retrying ? 'جارٍ المحاولة...' : 'إعادة المحاولة',
                    style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 16, fontWeight: FontWeight.w700),
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
    GoRoute(path: Routes.welcome, builder: (_, _) => const OnboardingOneScreen()),
    GoRoute(path: Routes.notification, builder: (_, _) => const NotificationScreen()),
    GoRoute(path: Routes.learningGoal, builder: (_, _) => const LearningGoalScreen()),
    GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
    GoRoute(path: Routes.subjectSelect, builder: (_, _) => const SubjectSelectScreen()),
    GoRoute(path: Routes.lessonPath, builder: (_, _) => const LessonPathScreen()),
    GoRoute(path: Routes.question, builder: (_, _) => const QuestionScreen()),
    GoRoute(path: Routes.feedback, builder: (_, _) => const FeedbackScreen()),
    GoRoute(path: Routes.achievements, builder: (_, _) => const AchievementsScreen()),
    GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
    GoRoute(path: Routes.signingIn, builder: (_, _) => const SignInLoadingScreen()),
  ],
);

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
          primary: _primary, onPrimary: Colors.white,
          secondary: _secondary, onSecondary: Colors.white,
          tertiary: _tertiary, onTertiary: Colors.white,
          error: _error, onError: Colors.white,
          surface: _background, onSurface: _textPrimary, outline: _outline,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'DIN2014Rounded', fontSize: 32, fontWeight: FontWeight.w800, height: 1.25),
          headlineLarge: TextStyle(fontFamily: 'DIN2014Rounded', fontSize: 24, fontWeight: FontWeight.w700, height: 1.33),
          headlineMedium: TextStyle(fontFamily: 'DIN2014Rounded', fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
          titleLarge: TextStyle(fontFamily: 'DIN2014Rounded', fontSize: 18, fontWeight: FontWeight.w700, height: 1.3),
          bodyLarge: TextStyle(fontFamily: 'DIN2014Rounded', fontSize: 18, fontWeight: FontWeight.w500, height: 1.44),
          bodyMedium: TextStyle(fontFamily: 'DIN2014Rounded', fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
          bodySmall: TextStyle(fontFamily: 'DIN2014Rounded', fontSize: 14, fontWeight: FontWeight.w400, height: 1.43),
          labelLarge: TextStyle(fontFamily: 'DIN2014Rounded', fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.05, height: 1.29),
          labelMedium: TextStyle(fontFamily: 'DIN2014Rounded', fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.05, height: 1.33),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontFamily: 'DIN2014Rounded', fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _primaryDark, textStyle: const TextStyle(fontFamily: 'DIN2014Rounded', fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: HaffarColors.grey6,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _outline)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _outline)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
