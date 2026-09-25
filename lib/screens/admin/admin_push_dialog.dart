import 'package:flutter/material.dart';

import '../../design_system/colors.dart';
import '../../models/admin_stats.dart';
import '../../services/admin_repository.dart';
import '../../utils/app_toast.dart';
import 'admin_widgets.dart';

/// Shared compose-and-send push dialog used by the user detail screen
/// (targeted) and the overview screen (broadcast / segment).
///
/// When [userId] is null the dialog offers an audience selector: all
/// devices, dormant (7d) or active (7d) users.
///
/// Shows the dialog, invokes admin-push, and toasts the result.
/// Returns the result, or null if the user cancelled / the send failed
/// (errors are toasted inside).
Future<AdminPushResult?> showAdminPushDialog({
  required BuildContext context,
  required AdminRepository repo,
  String? userId,
  String title = 'إرسال إشعار',
}) async {
  final ctrl = TextEditingController();
  var segment = 'all'; // broadcast audience: all | dormant_7d | active_7d
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: kAdminFont,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'نص الإشعار…',
                hintStyle: TextStyle(fontFamily: kAdminFont, fontSize: 14),
              ),
              style: const TextStyle(fontFamily: kAdminFont, fontSize: 14),
            ),
            if (userId == null) ...[
              const SizedBox(height: 8),
              const Text(
                'الفئة المستهدفة:',
                style: TextStyle(
                  fontFamily: kAdminFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: HaffarColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final opt in const [
                    ('all', 'الكل'),
                    ('dormant_7d', 'خاملون (7 أيام)'),
                    ('active_7d', 'نشطون (7 أيام)'),
                  ])
                    ChoiceChip(
                      label: Text(
                        opt.$2,
                        style: TextStyle(
                          fontFamily: kAdminFont,
                          fontSize: 12,
                          fontWeight: segment == opt.$1
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      selected: segment == opt.$1,
                      onSelected: (_) => setDialogState(() => segment = opt.$1),
                    ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: kAdminFont),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'إرسال',
              style: TextStyle(fontFamily: kAdminFont),
            ),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true || ctrl.text.trim().isEmpty || !context.mounted) {
    return null;
  }
  final body = ctrl.text.trim();
  try {
    final result = await repo.sendNotification(
      body: body,
      userId: userId,
      segment: userId == null && segment != 'all' ? segment : null,
    );
    if (context.mounted) {
      AppToast.success('تم الإرسال إلى ${result.targets} جهاز');
    }
    return result;
  } catch (e) {
    if (context.mounted) {
      AppToast.error(
        e,
        fallback: 'تعذر إرسال الإشعار',
        logContext: 'admin_push',
      );
    }
    return null;
  }
}
