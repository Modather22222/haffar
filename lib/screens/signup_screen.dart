import '../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import '../utils/app_toast.dart';
import '../utils/routes.dart';
import '../widgets/mascot.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Mascot(pose: MascotPose.shyWave, size: 110),
              const SizedBox(height: 8),
              const Text(
                'إنشاء حساب جديد',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'سجّل اسمك لتبدأ مغامرتك في التعلم',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  color: HaffarColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'اسم الحفار',
                  hintText: 'اختر اسماً مميزاً...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HaffarColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      AppToast.show('اكتب اسمك أولاً', isError: true);
                      return;
                    }
                    context.read<ProgressProvider>().login(name);
                    context.go(Routes.home);
                  },
                  child: const Text(
                    'إنشاء الحساب',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(Routes.login),
                child: const Text('لديّ حساب بالفعل'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
