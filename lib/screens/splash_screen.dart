import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../design_system/colors.dart';
import '../design_system/tokens/text_styles.dart';
import '../providers/content_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/session_provider.dart';
import '../utils/app_logger.dart';
import '../utils/app_toast.dart';
import '../utils/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    AppLog.info('splash _navigate start');
    final content = context.read<ContentProvider>();
    final session = context.read<SessionProvider>();
    final progress = context.read<ProgressProvider>();
    await content.loadContent();
    AppLog.info(
      'loadContent done status=${content.status} '
      'subjects=${content.subjects.length} questions=${content.totalQuestionCount()}',
    );
    if (content.status == ContentStatus.error) {
      AppLog.warn('content error, retrying once');
      await Future.delayed(const Duration(milliseconds: 800));
      await content.loadContent();
      AppLog.info('loadContent retry status=${content.status}');
      if (content.status == ContentStatus.error) {
        AppToast.show(
          content.errorMessage ?? 'تعذر تحميل المحتوى — حاول مرة أخرى',
          isError: true,
          duration: const Duration(seconds: 5),
        );
      }
    }
    // Hydrate persisted onboarding/identity flags before routing.
    await progress.loadLocalPrefs();
    await session.initUserData();
    AppLog.info(
      'initUserData done sync=${session.remoteSyncEnabled} '
      'signedIn=${session.isSignedIn} '
      'onboarded=${progress.hasCompletedOnboarding} '
      'subject=${progress.selectedSubjectId}',
    );
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    // Signed-in users always go home (skip welcome/onboarding on cold start).
    if (session.isSignedIn) {
      AppLog.info('route -> home (signed in)');
      context.go(Routes.home);
    } else {
      AppLog.info('route -> welcome (no session)');
      context.go(Routes.welcome);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                const Spacer(flex: 3),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/character/character (7).png',
                    width: 260,
                    height: 260,
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  'حفار',
                  style: TextStyle(
                    fontFamily: HaffarTextStyles.fontFamily,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: HaffarColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'احفر طريقك نحو النجاح',
                  style: TextStyle(
                    fontFamily: HaffarTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: HaffarColors.primaryDark,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
