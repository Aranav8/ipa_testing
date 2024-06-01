import 'package:firebase_messaging/firebase_messaging.dart';

import '../main.dart';

// Future<void> handleBackgroundMessage(RemoteMessage message) async {
//   print('Background Message Received:');
//   print('Title: ${message.notification?.title}');
//   print('Body: ${message.notification?.body}');
//   print('Data: ${message.data}');
// }

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    try {
      print("Initializing Firebase Messaging...");
      await _firebaseMessaging.requestPermission();
      final FCMToken = await _firebaseMessaging.getToken();
      if (FCMToken != null) {
        print('FCM Token: $FCMToken');
      } else {
        print('Failed to get FCM Token');
      }
      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }
}
