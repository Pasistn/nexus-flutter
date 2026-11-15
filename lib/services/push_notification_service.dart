import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/config/env.dart';

class PushNotificationService {
  PushNotificationService._();

  static const _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Wichtige Benachrichtigungen',
    description: 'Chatnachrichten, Anfragen und Bewertungen',
    importance: Importance.high,
  );

  static final _local = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get isAvailable => _ready;

  static String get platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  static Future<void> init() async {
    final options = Env.firebaseOptions;
    if (options == null) return;

    try {
      await Firebase.initializeApp(options: options);

      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      FirebaseMessaging.onMessage.listen(_showInForeground);
      unawaited(FirebaseMessaging.instance.requestPermission());
      _ready = true;
    } catch (e) {
      debugPrint('[push] disabled: $e');
    }
  }

  static Future<String?> token() async {
    if (!_ready) return null;
    return FirebaseMessaging.instance.getToken();
  }

  static Stream<String> get onTokenRefresh => _ready
      ? FirebaseMessaging.instance.onTokenRefresh
      : const Stream.empty();

  static Future<void> _showInForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    await _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
