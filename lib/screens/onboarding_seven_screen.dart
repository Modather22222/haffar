import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../design_system/components/progress_bar_ring.dart';
import '../providers/progress_provider.dart';
import '../utils/app_logger.dart';
import '../utils/app_toast.dart';
import '../utils/routes.dart';

class OnboardingSevenScreen extends StatefulWidget {
  const OnboardingSevenScreen({super.key});

  @override
  State<OnboardingSevenScreen> createState() => _OnboardingSevenScreenState();
}

class _OnboardingSevenScreenState extends State<OnboardingSevenScreen> {
  final _controller = TextEditingController();
  bool _hasText = false;
  bool _notifications = false;

  void _updateState() {
    setState(() => _hasText = _controller.text.isNotEmpty);
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notifications = value);
    if (value) {
      try {
        final status = await Permission.notification.request();
        if (mounted && status.isDenied) {
          setState(() => _notifications = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يجب السماح بالإشعارات لتفعيلها'),
              backgroundColor: HaffarColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (mounted && status.isPermanentlyDenied) {
          setState(() => _notifications = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'الإشعارات مرفوضة نهائياً — فعّلها من إعدادات الجهاز',
              ),
              backgroundColor: HaffarColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (mounted) {
          context.read<ProgressProvider>().enableNotifications();
        }
      } catch (e, st) {
        AppLog.error('notification permission request failed', e, st);
        if (!mounted) return;
        setState(() => _notifications = false);
        AppToast.error(
          e,
          fallback: 'تعذر طلب إذن الإشعارات — حاول مرة أخرى',
          logContext: 'notification permission',
          st: st,
        );
      }
    } else {
      context.read<ProgressProvider>().enableNotifications();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateState);
    _notifications = context.read<ProgressProvider>().notificationsEnabled;
  }

  @override
  void dispose() {
    _controller.removeListener(_updateState);
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: HaffarColors.grey2,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(child: HaffarProgressBar(progress: 0.4)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/character/character (12).png',
                        width: 100,
                        height: 140,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: HaffarSpeechBubble(
                          tailPosition: BubbleTailPosition.bottomRight,
                          message: 'عايز تجيب كم في امتحان الشهادة؟',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: false,
                    ),
                    inputFormatters: [_ArabicDigitsFormatter()],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'DIN2014Rounded',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: HaffarColors.grey1,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: HaffarColors.grey6,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: HaffarColors.grey5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: HaffarColors.grey5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: HaffarColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: InkWell(
                    onTap: () => _toggleNotifications(!_notifications),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: HaffarColors.grey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: _notifications
                                ? HaffarColors.primary
                                : HaffarColors.grey3,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'فعل الإشعارات',
                              style: TextStyle(
                                fontFamily: 'DIN2014Rounded',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: HaffarColors.grey1,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: _notifications,
                            activeThumbColor: HaffarColors.primary,
                            onChanged: (v) => _toggleNotifications(v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: HaffarPrimaryButton(
                      state: _hasText
                          ? HaffarPrimaryButtonState.enabled
                          : HaffarPrimaryButtonState.disabled,
                      label: 'استمر',
                      onPressed: _hasText
                          ? () {
                              final n = int.tryParse(_controller.text);
                              if (n == null || n < 140) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'يجب ان يكون الرقم اكبر من 140',
                                    ),
                                    backgroundColor: HaffarColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              context.push(Routes.onboardingEight);
                            }
                          : null,
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

/// Accepts both ASCII digits (0-9) and Arabic-Indic digits (٠-٩)
class _ArabicDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.replaceAll(
      RegExp(r'[^\u0030-\u0039\u0660-\u0669]'),
      '',
    );
    if (cleaned == newValue.text) return newValue;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}
