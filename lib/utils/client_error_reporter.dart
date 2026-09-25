import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_logger.dart';

/// Global client-error capture.
///
/// Design constraints (see plan P5):
///  - Never blocks or crashes the UI: every entry point is wrapped, the
///    buffer is bounded, and flushes happen on a debounce timer.
///  - Never reports PII: [scrub] redacts emails, secrets and long digit runs
///    before anything leaves the device; URLs lose their query strings.
///  - Batches: errors accumulate in [_buffer] and are flushed together
///    (server caps the batch at 50, we cap the buffer at 100).
///  - Crash-loop safe: each fingerprint is reported at most [_maxPerFingerprint]
///    times per app run.
class ClientErrorReporter {
  ClientErrorReporter._();
  static final ClientErrorReporter instance = ClientErrorReporter._();

  static const _flushDelay = Duration(seconds: 3);
  static const _retryDelay = Duration(seconds: 30);
  static const _maxBuffer = 100;
  static const _maxBatch = 50;
  static const _maxPerFingerprint = 20;
  static const _maxConsecutiveFailures = 5;
  static const _maxMessageLen = 2000;
  static const _maxStackLen = 8000;

  final List<Map<String, String>> _buffer = [];
  final Map<String, int> _reported = {};
  Timer? _timer;
  bool _flushing = false;
  int _consecutiveFailures = 0;
  bool _installed = false;
  String? _appVersion;

  bool get installed => _installed;

  /// Installs the global hooks. Call once from `main()` before `runApp`.
  /// Preserves the pre-existing behavior (presentError / swallow-and-log).
  void install() {
    if (_installed) return;
    _installed = true;
    FlutterError.onError = (details) {
      AppLog.error('FlutterError', details.exception, details.stack);
      record(details.exception, details.stack);
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLog.error('Uncaught async error', error, stack);
      record(error, stack);
      return true;
    };
  }

  /// Zone handler for `runZonedGuarded` — catches async errors that never
  /// reach [PlatformDispatcher.onError].
  void recordZoneError(Object error, StackTrace stack) {
    AppLog.error('Zone uncaught error', error, stack);
    record(error, stack);
  }

  /// Records [error]. Safe to call from anywhere; never throws.
  void record(Object error, StackTrace? stack) {
    try {
      final raw = error.toString();
      final fingerprint = fingerprintOf(raw, stack?.toString());
      final count = (_reported[fingerprint] ?? 0) + 1;
      _reported[fingerprint] = count;
      if (count > _maxPerFingerprint) return; // crash-loop guard

      if (_buffer.length >= _maxBuffer) _buffer.removeAt(0);
      _buffer.add({
        'fingerprint': fingerprint,
        'message': _truncate(
          scrub('${error.runtimeType}: $raw'),
          _maxMessageLen,
        ),
        'stack': _truncate(scrub(stack?.toString() ?? ''), _maxStackLen),
      });
      _scheduleFlush();
    } catch (e) {
      // The error hook itself must never propagate.
      debugPrint('ClientErrorReporter.record failed: $e');
    }
  }

  void _scheduleFlush() {
    if (_timer?.isActive ?? false) return;
    _timer = Timer(_flushDelay, () => unawaited(flush()));
  }

  /// Flushes the buffer as one RPC. On failure or when signed out, items are
  /// kept and retried (backoff) until [_maxConsecutiveFailures].
  Future<void> flush() async {
    if (_flushing || _buffer.isEmpty) return;
    _flushing = true;
    try {
      final batch = _buffer.length > _maxBatch
          ? _buffer.sublist(0, _maxBatch)
          : _buffer.sublist(0, _buffer.length);

      if (!_canSend()) {
        // Signed out / Supabase not ready: keep the batch (it may be an
        // init/login-screen error) and retry gently after login.
        _timer = Timer(_retryDelay, () => unawaited(flush()));
        return;
      }
      await _ensureVersion();
      await Supabase.instance.client.rpc(
        'report_client_errors',
        params: {'p_items': jsonEncode(batch.map(withMeta).toList())},
      );
      _buffer.removeRange(0, batch.length);
      _consecutiveFailures = 0;
    } catch (e) {
      _consecutiveFailures++;
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        _buffer.clear();
        _consecutiveFailures = 0;
      }
      AppLog.error('client_error report failed', e);
      if (_buffer.isNotEmpty) {
        _timer = Timer(_retryDelay, () => unawaited(flush()));
      }
    } finally {
      _flushing = false;
    }
  }

  bool _canSend() {
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false; // not initialized yet
    }
  }

  Future<void> _ensureVersion() async {
    if (_appVersion != null) return;
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.buildNumber.isEmpty
          ? info.version
          : '${info.version}+${info.buildNumber}';
    } catch (_) {
      _appVersion = 'unknown';
    }
  }

  /// Payload fields the server stores per event.
  Map<String, String> withMeta(Map<String, String> item) => {
    ...item,
    'app_version': _appVersion ?? 'unknown',
    'platform': defaultTargetPlatform.name,
    'device': kIsWeb ? 'web' : Platform.operatingSystemVersion,
  };

  /// Redacts PII from free-form error text. Static + pure for unit tests.
  @visibleForTesting
  static String scrub(String input) {
    var s = input;
    // JWTs and Supabase keys.
    s = s.replaceAll(
      RegExp(
        r'sbp_[A-Za-z0-9_-]+|sb_secret_[A-Za-z0-9_-]+|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]+',
      ),
      '[secret]',
    );
    // Email addresses.
    s = s.replaceAll(
      RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
      '[email]',
    );
    // Bearer/authorization headers.
    s = s.replaceAll(
      RegExp(r'bearer\s+[A-Za-z0-9._~+/-]+=*', caseSensitive: false),
      'Bearer [redacted]',
    );
    // Query strings may carry tokens / emails.
    s = s.replaceAll(RegExp(r'\?\S+'), '?[qs]');
    // Long digit runs (phone numbers, ids).
    s = s.replaceAll(RegExp(r'\d{8,}'), '[num]');
    return s;
  }

  /// Stable group key: first (digit-normalized) message line + first
  /// meaningful stack frame, hashed to 16 hex chars. Pure for unit tests.
  @visibleForTesting
  static String fingerprintOf(String message, String? stack) {
    final firstLine = message
        .split('\n')
        .first
        .trim()
        .replaceAll(RegExp(r'\d+'), '#');
    var frame = '';
    for (final line in (stack ?? '').split('\n')) {
      final t = line.trim();
      if (t.contains('.dart:') ||
          t.contains('package:') ||
          t.contains('.js:')) {
        frame = t.replaceAll(RegExp(r'\d+'), '#');
        break;
      }
    }
    return _hash('$firstLine|$frame');
  }

  static String _hash(String s) {
    // FNV-1a 32-bit with two offsets → 16 hex chars.
    var h1 = 0x811c9dc5;
    var h2 = 0x01000193;
    for (final c in s.codeUnits) {
      h1 = ((h1 ^ c) * 0x01000193) & 0xffffffff;
      h2 = ((h2 ^ c) * 0x9e3779b1) & 0xffffffff;
    }
    return h1.toRadixString(16).padLeft(8, '0') +
        h2.toRadixString(16).padLeft(8, '0');
  }

  static String _truncate(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);
}
