import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../routes/app_route.dart';
import '../../utils/spHelper.dart';

@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(message) async {
  await Firebase.initializeApp();
  log("Handling a background message $message");
}


// class AppNotification {
//
//   BuildContext? context;
//   FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
//   final _authInstance = FirebaseAuth.instance;
//
//   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   Future _onDidReceiveLocalNotification(int? id, String? title, String? body,
//       String? payload) async {}
//
//   Future _selectNotification(NotificationResponse? notificationResponse) async {
//     if (notificationResponse!.payload!.isEmpty) {
//       var data = jsonDecode(notificationResponse.payload!);
//       onNotificationClick(data);
//     }
//   }
//
//   ///local notification setup
//   Future<void> configLocalNotification() async {
//     await saveNotificationToken(_authInstance);
//
//     if (!kIsWeb) {
//       if (!kIsWeb && Platform.isIOS) {
//         // set iOS Local notification.
//         var initializationSettingsAndroid =
//         const AndroidInitializationSettings('ic_launcher');
//         var initializationSettingsIOS = DarwinInitializationSettings(
//           requestSoundPermission: true,
//           requestBadgePermission: true,
//           requestAlertPermission: true,
//           onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
//         );
//         var initializationSettings = InitializationSettings(
//             android: initializationSettingsAndroid,
//             iOS: initializationSettingsIOS);
//         await flutterLocalNotificationsPlugin.initialize(initializationSettings,
//             onDidReceiveNotificationResponse: (val) =>
//                 _selectNotification(val));
//       } else {
//         // set Android Local notification.
//         var initializationSettingsAndroid =
//         const AndroidInitializationSettings('@mipmap/ic_launcher');
//         var initializationSettingsIOS = DarwinInitializationSettings(
//             onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
//         var initializationSettings = InitializationSettings(
//             android: initializationSettingsAndroid,
//             iOS: initializationSettingsIOS);
//         await flutterLocalNotificationsPlugin.initialize(initializationSettings,
//             onDidReceiveNotificationResponse: (val) =>
//                 _selectNotification(val));
//       }
//     }
//   }
//
//   ///handle firebase push notification
//   getNotification() async {
//     firebaseMessaging.requestPermission(
//         sound: true, badge: true, alert: true, provisional: false);
//     await firebaseMessaging.setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//     FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print(message);
//       showNotification(message);
//       return;
//     });
//     FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
//   }
//
//   void handleMessage(
//       RemoteMessage? message,
//       ) async {
//     if (message == null) return;
//
//     print('app opend: ${message.data}');
//     List<String> params = [
//       message.data['receiverUserEmail'],
//       message.data['receiverUserID'],
//       message.data['senderId'],
//     ];
//     Map<String, String> param = {
//       "receiverUserEmail":   message.data['receiverUserEmail'],
//       "receiverUserID":  message.data['receiverUserID'],
//       "senderId":  message.data['senderId'],
//     };
//
//     await Get.toNamed(PageConst.chatView, parameters: param);
//
//     AppSharedPrefs.setcartProductList(params);
//
//   }
//   ///show local notification in device
//   void showNotification(message) async {
//     var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
//       'com.example.myapp',
//       'tapln',
//       playSound: true,
//       enableVibration: true,
//       importance: Importance.high,
//       priority: Priority.high,
//
//     );
//     var iOSPlatformChannelSpecifics = const DarwinNotificationDetails(
//       presentSound: true,
//       presentAlert: true,
//       presentBadge: true,
//     );
//     var platformChannelSpecifics = NotificationDetails(
//         android: androidPlatformChannelSpecifics,
//         iOS: iOSPlatformChannelSpecifics);
//
//     await flutterLocalNotificationsPlugin.show(
//         0,
//         message.notification.title.toString(),
//         message.notification.body.toString(),
//         platformChannelSpecifics,
//         payload: jsonEncode(message.data));
//   }
//
//
//   void onNotificationClick(data) {
//     print(data);
//     // Get.toNamed(Routes.ORDER_DETAIL, arguments: {'orderId': data['orderId']});
//   }
//
//   Future saveNotificationToken(FirebaseAuth authInstance) async {
//     String? token = await FirebaseMessaging.instance.getToken();
//     final String userId = authInstance.currentUser!.uid;
//     final userDocRef =
//     FirebaseFirestore.instance.collection('users').doc(userId);
//
//     // Check if the user document exists
//     final userSnapshot = await userDocRef.get();
//
//     if (userSnapshot.exists) {
//       // Check if the 'token' field exists
//       if (userSnapshot.data()!.containsKey('token')) {
//         print('token exists updating token ');
//         // Update the existing 'token'
//         await userDocRef.update({'token': token});
//       } else {
//         // Create the 'token' field and write the token
//         print('no token available create token');
//         await userDocRef.set({'token': token}, SetOptions(merge: true));
//       }
//     }
//   }
// }
