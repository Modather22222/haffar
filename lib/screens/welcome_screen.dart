import '../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/routes.dart';
import '../widgets/mascot.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Mascot(pose: MascotPose.wave, size: 190),
              const SizedBox(height: 24),
              const Text(
                'مرحباُ بك يا حفار!',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'تعلم بطريقة ممتعة وتفاعلية. حل الأسئلة، اجمع النجوم، وتقدم في رحلة التعلم!',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  color: Color(0xFF3f4a36),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _cta(context, 'ابدأ الآن', HaffarColors.primary, () {
                context.read<AppProvider>().completeOnboarding();
                context.go(Routes.signup);
              }),
              const SizedBox(height: 12),
              _cta(
                context,
                'لديّ حساب',
                HaffarColors.surfaceHigh,
                () => context.go(Routes.login),
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cta(
    BuildContext ctx,
    String label,
    Color color,
    VoidCallback onTap, {
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.white : color,
          foregroundColor: isOutlined ? color : Colors.white,
          side: isOutlined ? BorderSide(color: color, width: 2) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isOutlined ? color : Colors.white,
          ),
        ),
      ),
    );
  }
}
