import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/utils/app_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AppError.userMessage', () {
    test('maps already-registered AuthException', () {
      final msg = AppError.userMessage(
        AuthException('User has already been registered'),
      );
      expect(msg, contains('مسجل بالفعل'));
      expect(msg, isNot(contains('already')));
    });

    test('maps invalid credentials AuthException', () {
      final msg = AppError.userMessage(
        AuthException('Invalid login credentials'),
      );
      expect(msg, contains('غير صحيحة'));
      expect(msg, isNot(contains('Invalid')));
    });

    test('maps email not confirmed', () {
      final msg = AppError.userMessage(AuthException('Email not confirmed'));
      expect(msg, contains('تأكيد الإيميل'));
    });

    test('never returns raw English auth message as fallback', () {
      final msg = AppError.userMessage(AuthException('Something odd happened'));
      expect(msg, AppError.generic);
      expect(msg, isNot(contains('Something')));
    });

    test('maps Postgrest permission denial', () {
      final msg = AppError.userMessage(
        PostgrestException(message: 'permission denied', code: '42501'),
      );
      expect(msg, AppError.permissionDenied);
    });

    test('maps Postgrest unauthorized', () {
      final msg = AppError.userMessage(
        PostgrestException(message: 'JWT expired', code: '401'),
      );
      expect(msg, AppError.notSignedIn);
    });

    test('maps Postgrest not found', () {
      final msg = AppError.userMessage(
        PostgrestException(message: 'no rows returned', code: 'PGRST116'),
      );
      expect(msg, AppError.notFound);
    });

    test('maps TimeoutException', () {
      final msg = AppError.userMessage(TimeoutException('took too long'));
      expect(msg, AppError.timeout);
    });

    test('maps network-looking strings', () {
      final msg = AppError.userMessage(
        Exception('SocketException: Failed host lookup: example.com'),
      );
      expect(msg, AppError.network);
    });

    test('uses custom fallback when provided', () {
      final msg = AppError.userMessage(
        Exception('boom'),
        fallback: 'رسالة مخصصة',
      );
      expect(msg, 'رسالة مخصصة');
    });

    test('defaults to generic Arabic for unknown errors', () {
      final msg = AppError.userMessage(Object());
      expect(msg, AppError.generic);
      expect(msg, isNot(contains('Object')));
    });

    test('maps StateError (missing config)', () {
      final msg = AppError.userMessage(StateError('Missing SUPABASE_URL'));
      expect(msg, contains('إعدادات'));
    });
  });
}
