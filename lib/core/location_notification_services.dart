// // notification_services.dart
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
//
// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _flutterNotificationPlugin =
//       FlutterLocalNotificationsPlugin();
//
//   static Future<void> initializeNotifications() async {
//     // Initialize time zones
//     tz.initializeTimeZones();
//
//     const AndroidInitializationSettings androidInitializationSettings =
//         AndroidInitializationSettings('transparent');
//     final InitializationSettings initializationSettings =
//         InitializationSettings(android: androidInitializationSettings);
//     await _flutterNotificationPlugin.initialize(initializationSettings);
//     print('Notification service initialized');
//   }
//
//   static Future<void> scheduleNotification() async {
//     const AndroidNotificationDetails androidNotificationDetails =
//         AndroidNotificationDetails(
//       'high_importance_channel',
//       'channelName',
//       channelDescription: 'Channel description',
//     );
//
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidNotificationDetails);
//
//     // Access time zone instance
//     final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
//
//     // Convert to Indian time zone (Asia/Kolkata)
//     final indianTimeZone = tz.getLocation('Asia/Kolkata');
//     final scheduledTime = tz.TZDateTime.now(indianTimeZone).add(
//         const Duration(minutes: 1)); // Schedule notification 1 minute from now
//     print('Scheduling notification for: $scheduledTime');
//
//     try {
//       await _flutterNotificationPlugin.zonedSchedule(
//         0,
//         'Reminder',
//         'Don\'t forget to open the app and refresh your location!',
//         scheduledTime,
//         platformChannelSpecifics,
//         androidAllowWhileIdle: true,
//         uiLocalNotificationDateInterpretation:
//             UILocalNotificationDateInterpretation.absoluteTime,
//       );
//       print('Notification scheduled');
//
//       // Convert scheduled UTC time to Indian time zone
//       // final scheduledTimeLocal = tz.TZDateTime.from(
//       //   scheduledTime,
//       //   indianTimeZone,
//       // );
//       // print('Scheduled notification for: $scheduledTimeLocal');
//
//       // Print message indicating notification sent
//       print('Notification sent!');
//     } catch (e) {
//       // Handle error if notification scheduling fails
//       print('Error scheduling notification: $e');
//     }
//   }
// }
