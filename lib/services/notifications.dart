import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications {
  final FlutterLocalNotificationsPlugin _notifications;

  Notifications([String iconName = 'ic_notification'])
      : _notifications = FlutterLocalNotificationsPlugin() {
    _notifications.initialize(InitializationSettings(
      AndroidInitializationSettings(iconName),
      IOSInitializationSettings(),
    ));
  }

  void show(int id, String title, String body,
          NotificationDetails notificationDetails) =>
      _notifications.show(id, title, body, notificationDetails);
}
