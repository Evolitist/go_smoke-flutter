import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications {
  static final Notifications _singleton = Notifications._();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  factory Notifications() => _singleton;

  Notifications._() {
    _notifications.initialize(
        InitializationSettings(
          AndroidInitializationSettings('ic_notification'),
          IOSInitializationSettings(),
        ), onSelectNotification: (payload) {
      print('tapped notification, data - $payload');
    });
  }

  void show(int id, String title, String body,
          NotificationDetails notificationDetails) =>
      _notifications.show(id, title, body, notificationDetails);
}
