import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../providers/progress_provider.dart';
import '../providers/session_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_error.dart';
import '../utils/app_logger.dart';
import '../utils/routes.dart';

/// Onboarding — email + password sign-up so Haffar can remember the user.
class OnboardingFourteenScreen extends StatefulWidget {
  const OnboardingFourteenScreen({super.key});

  @override
  State<OnboardingFourteenScreen> createState() =>
      _OnboardingFourteenScreenState();
}

class _OnboardingFourteenScreenState extends State<OnboardingFourteenScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;
  bool _awaitingConfirmation = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _emailValid => RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  ).hasMatch(_emailController.text.trim());
  bool get _passwordValid => _passwordController.text.length >= 8;
  bool get _canSubmit => _emailValid && _passwordValid && !_loading;

  Future<void> _signUp() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final auth = AuthService(Supabase.instance.client);
      final name = context.read<ProgressProvider>().userName;
      final res = await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: name,
      );
      if (!mounted) return;
      // Email confirmation is disabled in the dashboard — expect a session.
      // Fall back to the confirmation notice if Supabase still requires it.
      if (res.needsConfirmation) {
        setState(() {
          _loading = false;
          _awaitingConfirmation = true;
        });
        return;
      }
      await context.read<SessionProvider>().initUserData();
      if (!mounted) return;
      context.read<ProgressProvider>().login(name);
      messenger.showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
      );
      final lastErr = context.read<SessionProvider>().lastInitError;
      if (lastErr != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('تعذر تحميل بعض البيانات: $lastErr'),
            backgroundColor: HaffarColors.error,
          ),
        );
      }
      context.go(Routes.onboardingFifteen);
    } catch (e, st) {
      AppLog.error('onboarding signup failed', e, st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(e);
      });
    }
  }

  String _messageFor(Object e) {
    return AppError.userMessage(
      e,
      fallback: 'تعذر إنشاء الحساب — تحقق من الإنترنت وحاول مجدداً',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_awaitingConfirmation) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/character/character (12).png',
                      width: 180,
                      height: 220,
                    ),
                    const SizedBox(height: 24),
                    const HaffarSpeechBubble(
                      message:
                          'بعتنا لك رابط تأكيد على إيميلك — افتحه عشان نفعّل حسابك',
                      tailPosition: BubbleTailPosition.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: HaffarPrimaryButton(
                        label: 'فهمت',
                        onPressed: () => context.go(Routes.signIn),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const HaffarSpeechBubble(
                        message: 'ادخل ايميل وكلمة مرور عشان حفار يتذكرك',
                        tailPosition: BubbleTailPosition.center,
                      ),
                      const SizedBox(height: 12),
                      Image.asset(
                        'assets/character/character (10).png',
                        width: 200,
                        height: 200,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(
                            fontFamily: 'DIN2014Rounded',
                            color: HaffarColors.grey3,
                          ),
                          filled: true,
                          fillColor: HaffarColors.grey6,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textDirection: TextDirection.ltr,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Password (8+)',
                          hintStyle: const TextStyle(
                            fontFamily: 'DIN2014Rounded',
                            color: HaffarColors.grey3,
                          ),
                          filled: true,
                          fillColor: HaffarColors.grey6,
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: HaffarColors.grey3,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'DIN2014Rounded',
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: HaffarPrimaryButton(
                          state: _canSubmit
                              ? HaffarPrimaryButtonState.enabled
                              : HaffarPrimaryButtonState.disabled,
                          label: _loading ? 'جارٍ الإنشاء...' : 'استمر',
                          onPressed: _canSubmit ? _signUp : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.push(Routes.signIn),
                        child: const Text(
                          'لديّ حساب بالفعل',
                          style: TextStyle(
                            fontFamily: 'DIN2014Rounded',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: HaffarColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: HaffarColors.grey5),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: HaffarColors.grey2,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
