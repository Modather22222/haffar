import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../design_system/colors.dart';
import '../design_system/tokens/text_styles.dart';
import '../providers/app_provider.dart';
import '../utils/routes.dart';
import 'onboarding_one_screen.dart';

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
    final p = context.read<AppProvider>();
    await p.loadContent();
    if (p.contentStatus == ContentStatus.error) {
      await Future.delayed(const Duration(milliseconds: 800));
      await p.loadContent();
    }
    await p.initUserData();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    if (!provider.hasLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingOneScreen()),
      );
    } else if (!provider.hasCompletedOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingOneScreen()),
      );
    } else if (provider.selectedSubjectId == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingOneScreen()),
      );
    } else {
      context.go(Routes.home);
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
                  'استكشف عالم المعرفة',
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
