import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../providers/session_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_error.dart';
import '../utils/app_logger.dart';
import '../utils/routes.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

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

  Future<void> _signIn() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService(Supabase.instance.client).signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      final session = context.read<SessionProvider>();
      await session.initUserData();
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('أهلاً بعودتك!')));
      if (session.lastInitError != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'تم تسجيل الدخول، لكن تعذر تحميل بعض البيانات: '
              '${session.lastInitError}',
            ),
            backgroundColor: HaffarColors.error,
          ),
        );
      }
      context.go(Routes.home);
    } catch (e, st) {
      AppLog.error('sign-in failed', e, st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(e);
      });
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (!_emailValid) {
      setState(() => _error = 'اكتب إيميل صحيح أولاً لإعادة التعيين');
      return;
    }
    setState(() => _error = null);
    try {
      await AuthService(Supabase.instance.client).resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('بعتنا رابط إعادة تعيين كلمة المرور على إيميلك'),
        ),
      );
    } catch (e, st) {
      AppLog.error('reset password failed', e, st);
      if (!mounted) return;
      setState(
        () => _error = AppError.userMessage(
          e,
          fallback: 'تعذر إرسال رابط إعادة التعيين — حاول مرة أخرى',
        ),
      );
    }
  }

  String _messageFor(Object e) {
    if (e is AuthException) {
      return AppError.userMessage(e);
    }
    return AppError.userMessage(
      e,
      fallback: 'تعذر تسجيل الدخول — تحقق من الإنترنت وحاول مجدداً',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Image.asset(
                    'assets/character/character (10).png',
                    width: 120,
                    height: 150,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontFamily: 'DIN2014Rounded',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: HaffarColors.grey1,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(
                        fontFamily: 'DIN2014Rounded',
                        color: HaffarColors.grey3,
                      ),
                      filled: true,
                      fillColor: HaffarColors.grey6,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
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
                      hintText: 'Password',
                      hintStyle: TextStyle(
                        fontFamily: 'DIN2014Rounded',
                        color: HaffarColors.grey3,
                      ),
                      filled: true,
                      fillColor: HaffarColors.grey6,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _loading ? null : _forgotPassword,
                      child: Text(
                        'نسيت كلمة المرور؟',
                        style: TextStyle(
                          fontFamily: 'DIN2014Rounded',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: HaffarColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: HaffarPrimaryButton(
                      state: _canSubmit
                          ? HaffarPrimaryButtonState.enabled
                          : HaffarPrimaryButtonState.disabled,
                      label: _loading ? 'جارٍ تسجيل الدخول...' : 'تسجيل الدخول',
                      onPressed: _canSubmit ? _signIn : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => context.push(Routes.onboardingFourteen),
                    child: Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(
                        fontFamily: 'DIN2014Rounded',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: HaffarColors.grey3,
                      ),
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
}
