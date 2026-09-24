import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';

/// Push notification wiring: FCM token registration (stored in `push_tokens`)
/// plus foreground display via a local-notification channel.
///
/// Best-effort by design — any failure is logged, never fatal to the app.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  static const String _channelId = 'streak_alerts';
  static const String _channelName = 'تنبيهات السلسلة';
  static const String _channelDesc = 'تذكير بحماية سلسلتك اليومية';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _inited = false;
  bool _registering = false;

  /// Call once at startup (after Supabase.initialize). Safe to call again.
  Future<void> init() async {
    if (_inited) return;
    try {
      await Firebase.initializeApp();

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      );
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // Foreground messages: system tray only shows them in background —
      // mirror to the local channel while the app is open.
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (t) => unawaited(_upsertToken(t)),
      );
      _inited = true;
      AppLog.info('PushService init OK');
    } catch (e, st) {
      AppLog.error('PushService init', e, st);
    }
  }

  /// Request permission and register this device — call after sign-in.
  Future<void> register() async {
    if (!_inited || _registering) return;
    _registering = true;
    try {
      final status = await Permission.notification.request();
      AppLog.info('notification permission=${status.name}');
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _upsertToken(token);
        AppLog.info('fcm token registered len=${token.length}');
      }
    } catch (e, st) {
      AppLog.error('PushService register', e, st);
    } finally {
      _registering = false;
    }
  }

  /// Drop this device's token — call BEFORE sign-out (RLS needs the uid).
  Future<void> unregister() async {
    if (!_inited) return;
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      final token = await FirebaseMessaging.instance.getToken();
      if (uid != null && token != null) {
        await Supabase.instance.client
            .from('push_tokens')
            .delete()
            .eq('user_id', uid)
            .eq('token', token);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e, st) {
      AppLog.warn('PushService unregister failed: $e');
      AppLog.error('PushService unregister', e, st);
    }
  }

  Future<void> _upsertToken(String token) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await Supabase.instance.client.from('push_tokens').upsert({
        'user_id': uid,
        'token': token,
        'platform': 'android',
      }, onConflict: 'user_id,token');
    } catch (e, st) {
      AppLog.error('PushService upsert token', e, st);
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    unawaited(
      _local.show(
        id: n.hashCode,
        title: n.title,
        body: n.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      ),
    );
  }
}
