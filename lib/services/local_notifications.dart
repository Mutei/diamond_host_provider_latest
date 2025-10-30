// lib/services/local_notifications.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppLocalNotifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Android 8.0+ channel
    const channel = AndroidNotificationChannel(
      'welcome_channel',
      'Welcome',
      description: 'Welcome and onboarding messages',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _inited = true;
  }

  static Future<void> showWelcome({
    required String title,
    required String body,
  }) async {
    await init(); // ensure ready

    const android = AndroidNotificationDetails(
      'welcome_channel',
      'Welcome',
      channelDescription: 'Welcome and onboarding messages',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();

    await _plugin.show(
      9001, // arbitrary id
      title,
      body,
      const NotificationDetails(android: android, iOS: ios),
    );
  }
}
