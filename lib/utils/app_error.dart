import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_logger.dart';

/// Maps any thrown object to a short, user-friendly Arabic message.
/// Never surface raw [toString] / English exception text in the UI.
abstract class AppError {
  AppError._();

  /// Default copy when nothing more specific matches.
  static const String generic = 'حدث خطأ غير متوقع — حاول مرة أخرى';

  static const String network =
      'تعذر الاتصال بالخادم — تحقق من الإنترنت وحاول مجدداً';

  static const String timeout = 'استغرق الطلب وقتاً طويلاً — حاول مرة أخرى';

  static const String notSignedIn = 'سجّل الدخول أولاً لحفظ تقدمك';

  static const String permissionDenied = 'ليست لديك صلاحية تنفيذ هذه العملية';

  static const String notFound = 'لم يتم العثور على البيانات المطلوبة';

  static const String contentLoad =
      'تعذر تحميل المحتوى — تحقق من الإنترنت وحاول مجدداً';

  /// Converts [e] into an Arabic message safe to show in snackbars/inline text.
  static String userMessage(Object e, {String? fallback}) {
    // Supabase Auth
    if (e is AuthException) return _auth(e);
    // Supabase PostgREST / database
    if (e is PostgrestException) return _postgrest(e);
    // Storage / realtime wrappers that still expose a message
    if (e is StorageException) return network;
    // Network
    if (e is TimeoutException) return timeout;
    if (e is SocketException ||
        e is HttpException ||
        e is HandshakeException ||
        e is TlsException) {
      return network;
    }
    // dart:io / package:http style messages
    final raw = e.toString().toLowerCase();
    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('connection reset') ||
        raw.contains('connection refused') ||
        raw.contains('connection closed') ||
        raw.contains('network is unreachable') ||
        raw.contains('clientexception') ||
        raw.contains('xmlhttprequest') ||
        raw.contains('internet')) {
      return network;
    }
    if (raw.contains('timeout') || raw.contains('timed out')) {
      return timeout;
    }
    // Misconfiguration / missing env
    if (e is StateError || e is ArgumentError || e is TypeError) {
      return 'تعذر تشغيل الخدمة — تأكد من إعدادات التطبيق';
    }
    return fallback ?? generic;
  }

  static String _auth(AuthException e) {
    final m = e.message.toLowerCase();
    final code = (e.code ?? '').toLowerCase();

    if (m.contains('already registered') ||
        m.contains('already been registered') ||
        code.contains('email_exists')) {
      return 'هذا الإيميل مسجل بالفعل — سجّل الدخول بدلاً من ذلك';
    }
    if (m.contains('invalid login') ||
        m.contains('invalid credentials') ||
        m.contains('email or password') ||
        code.contains('invalid_credentials')) {
      return 'الإيميل أو كلمة المرور غير صحيحة';
    }
    if (m.contains('email not confirmed') ||
        m.contains('not confirmed') ||
        code.contains('email_not_confirmed')) {
      return 'يجب تأكيد الإيميل أولاً';
    }
    if (m.contains('user not found') || code.contains('user_not_found')) {
      return 'لا يوجد حساب بهذا الإيميل';
    }
    if (m.contains('weak_password') ||
        (m.contains('password') && m.contains('least'))) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    if (m.contains('invalid') && m.contains('email')) {
      return 'تأكد من صحة الإيميل';
    }
    if (m.contains('rate limit') ||
        m.contains('too many') ||
        code.contains('over_email_send_rate_limit')) {
      return 'محاولات كثيرة جداً — انتظر قليلاً ثم حاول مجدداً';
    }
    if (m.contains('network') || m.contains('fetch')) {
      return network;
    }
    if (m.contains('session') || m.contains('token')) {
      return 'انتهت الجلسة — سجّل الدخول مرة أخرى';
    }
    // Auth errors are still user-facing — keep Arabic, never raw English.
    return generic;
  }

  static String _postgrest(PostgrestException e) {
    final code = e.code ?? '';
    final msg = (e.message).toLowerCase();

    if (code == '401' ||
        code == 'PGRST301' ||
        msg.contains('jwt') ||
        msg.contains('session')) {
      return notSignedIn;
    }
    if (code == '403' || code == '42501' || msg.contains('permission')) {
      return permissionDenied;
    }
    if (code == '404' || msg.contains('not found')) {
      return notFound;
    }
    if (code == '409' || msg.contains('duplicate') || msg.contains('unique')) {
      return 'البيانات مسجلة بالفعل';
    }
    if (code == '42P01' || msg.contains('does not exist')) {
      return notFound;
    }
    if (code == 'PGRST116' || msg.contains('no rows')) {
      return notFound;
    }
    if (code.startsWith('PGRST') && code != 'PGRST116') {
      // Other PostgREST internal errors — still don't leak SQL.
      return generic;
    }
    return network;
  }

  /// Log + map in one call. Returns the user-facing message.
  static String log(Object e, StackTrace? st, String context) {
    AppLog.error(context, e, st);
    return userMessage(e);
  }
}
