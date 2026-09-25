import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../utils/content_validators.dart';
import '../admin_widgets.dart';

/// Shared dialog/snackbar helpers for the content editor screens.
Future<String?> showTextPromptDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  int max = 300,
  String? Function(String)? validate,
}) {
  final controller = TextEditingController(text: initial);
  String? error;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: kAdminFont,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          maxLength: max,
          style: const TextStyle(fontFamily: kAdminFont, fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontFamily: kAdminFont, fontSize: 13),
            errorText: error,
            errorStyle: const TextStyle(fontFamily: kAdminFont, fontSize: 11),
          ),
          onChanged: (_) => setState(() => error = null),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: kAdminFont),
            ),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              final message =
                  validate?.call(value) ??
                  validateRequiredText(value, label, max: max);
              if (message != null) {
                setState(() => error = message);
                return;
              }
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text(
              'حفظ',
              style: TextStyle(
                fontFamily: kAdminFont,
                fontWeight: FontWeight.w700,
                color: HaffarColors.primary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'حذف',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: kAdminFont,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: kAdminFont,
          fontSize: 13,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('إلغاء', style: TextStyle(fontFamily: kAdminFont)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              fontFamily: kAdminFont,
              fontWeight: FontWeight.w700,
              color: destructive ? HaffarColors.error : HaffarColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Success or error snackbar with admin typography.
void editorSnack(BuildContext context, {String? success, Object? error}) {
  if (!context.mounted) return;
  final message = success ?? _saveErrorText(error);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: kAdminFont,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        backgroundColor: error != null
            ? HaffarColors.error
            : HaffarColors.primaryDark,
      ),
    );
}

/// Maps a caught write/RPC error to a short Arabic action message.
String _saveErrorText(Object? error) {
  final s = error?.toString() ?? '';
  if (s.contains('not authorized')) return 'غير مصرح — هذه العملية للأدمن فقط';
  if (s.contains('row-level security')) {
    return 'غير مصرح بتعديل هذا المحتوى';
  }
  if (s.contains('duplicate key')) return 'المعرّف مستخدم مسبقاً';
  if (s.contains('SocketException') ||
      s.contains('TimeoutException') ||
      s.contains('timeout') ||
      s.contains('Failed host')) {
    return 'تحقق من الاتصال بالإنترنت';
  }
  return 'تعذر إتمام العملية';
}
