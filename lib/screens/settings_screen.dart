import '../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../utils/routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'تسجيل الخروج',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'هل تريد الخروج من حسابك؟',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 15,
            color: HaffarColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // Always leave settings — local state clears even if the server call
    // fails; SessionProvider surfaces any server error via AppToast.
    await context.read<SessionProvider>().signOut();
    if (!context.mounted) return;
    context.go(Routes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _tile(
              Icons.notifications,
              'تفعيل التنبيهات',
              'تذكيرك بالعودة يومياُ للتعلم',
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
            _tile(
              Icons.volume_up,
              'المؤثرات الصوتية',
              'تشغيل أصوات عند الإجابة',
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
            _tile(Icons.language, 'اللغة', 'العربية'),
            _tile(Icons.palette, 'المظهر', 'فاتح'),
            const SizedBox(height: 24),
            _tile(
              Icons.logout,
              'تسجيل الخروج',
              'الخروج من الحساب الحالي',
              onTap: () => _signOut(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String subtitle, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HaffarColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: HaffarColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      color: HaffarColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              const Icon(Icons.chevron_left, color: HaffarColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
