import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notifications.dart';

//TODO: switch to native implementation
class FCM {
  static final FCM _singleton = FCM._();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final Notifications _notifications = Notifications();

  factory FCM() => _singleton;

  FCM._();

  void init([ValueChanged<String> tokenCallback]) {
    _firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(
        sound: true,
        badge: true,
        alert: true,
      ),
    );
    _firebaseMessaging.configure(
      onMessage: (message) async {
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
      onLaunch: (message) async {
        print(message);
      },
      onResume: (message) async {
        print(message);
      },
    );
    _firebaseMessaging.onTokenRefresh.listen(tokenCallback);
  }
}
