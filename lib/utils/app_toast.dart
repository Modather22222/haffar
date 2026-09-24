import 'package:flutter/material.dart';

import '../design_system/colors.dart';
import 'app_error.dart';
import 'app_logger.dart';

/// Root [ScaffoldMessenger] key so providers (no BuildContext) can still
/// show snackbars. Wired in `MaterialApp.router(scaffoldMessengerKey: ...)`.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// App-wide snackbar helper with Arabic, user-friendly copy.
abstract class AppToast {
  AppToast._();

  static const _font = 'BeVietnamPro';

  /// Shows [message] as a snackbar. Prefer [error] / [success] from call sites.
  static void show(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? HaffarColors.error : HaffarColors.grey1,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Maps [e] (or uses [fallback]) and shows an error snackbar.
  static void error(
    Object e, {
    String? fallback,
    String? logContext,
    StackTrace? st,
  }) {
    if (logContext != null) AppLog.error(logContext, e, st);
    show(fallback ?? AppError.userMessage(e), isError: true);
  }

  static void success(String message) => show(message);

  /// Inline-friendly error text for form fields (no snackbar).
  static String inline(Object e, {String? fallback}) =>
      AppError.userMessage(e, fallback: fallback);
}
