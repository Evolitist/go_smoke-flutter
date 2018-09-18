import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notifications.dart';

class FCM {
  final FirebaseMessaging _firebaseMessaging;
  final Notifications _notifications;

  FCM() : _firebaseMessaging = FirebaseMessaging(),
  _notifications = Notifications() {
    _firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(
        sound: true,
        badge: true,
        alert: true,
      ),
    );
    _firebaseMessaging.configure(
      onMessage: (message) {
        print(message);
        _notifications.show(
          1,
          message['notification']['title'],
          message['notification']['body'],
          NotificationDetails(
            AndroidNotificationDetails(
              'general',
              'General notifications',
              '',
              importance: Importance.High,
            ),
            IOSNotificationDetails(),
          ),
        );
      },
    );
    _firebaseMessaging.getToken().then((value) => print(value));
  }
}