
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:googleapis_auth/auth_io.dart';

import '../../firebase_options.dart';
import '../../routes/app_route.dart';

@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log("Handling a background message ${message.messageId}");
}

class AppNotification {
  BuildContext? context;
  String? accessToken;
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future _onDidReceiveLocalNotification(
      int? id, String? title, String? body, String? payload) async {}

  Future _selectNotification(NotificationResponse? notificationResponse) async {
    var data = jsonDecode(notificationResponse!.payload!);
    // print("_selectNotification ${notificationResponse.payload.toString()}");
    Map<String, String> param = {
      "receiverUserEmail":   data['receiverUserEmail'],
      "receiverUserID":  data['receiverUserID'],
      "senderId":  data['senderId'],
    };
    Get.toNamed(PageConst.chatView, parameters: param);
    return;
  }

  ///local notification setup
  Future<void> configLocalNotification() async {
    if (!kIsWeb) {
      if (!kIsWeb && Platform.isIOS) {
        // set iOS Local notification.
        var initializationSettingsAndroid =
            const AndroidInitializationSettings('ic_launcher');
        var initializationSettingsIOS = DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
          onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
        );
        var initializationSettings = InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
        await flutterLocalNotificationsPlugin.initialize(initializationSettings,
            onDidReceiveNotificationResponse: (val) =>
                _selectNotification(val));
      } else {
        // set Android Local notification.
        var initializationSettingsAndroid =
            const AndroidInitializationSettings('@mipmap/ic_launcher');
        var initializationSettingsIOS = DarwinInitializationSettings(
            onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
        var initializationSettings = InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
        await flutterLocalNotificationsPlugin.initialize(initializationSettings,
            onDidReceiveNotificationResponse: (val) =>
                _selectNotification(val));
      }
    }
  }

  ///handle firebase push notification
  getNotification() async {
    FirebaseMessaging.onMessage.listen((event) {
      return;
    });
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(fcmMessageHandler);
    await firebaseMessaging.getInitialMessage().then(fcmMessageHandler);
  }

  ///generate token for fcm
  Future<String?> registerNotification() async {

      if (Platform.isIOS) {
        return await firebaseMessaging.getToken();
      } else {
        return await firebaseMessaging.getToken();
      }

  }

  ///show local notification in device
  void showNotification(RemoteMessage message) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      Platform.isAndroid ? 'ch.kayosys.steuern59' : 'ch.steuern59',
      'Taxley Notification Service',
      playSound: true,
      enableVibration: true,
      importance: Importance.max,
      priority: Priority.high,
    );
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
        math.Random().nextInt(1),
        message.notification!.title,
        message.notification!.body,
        platformChannelSpecifics,
        payload: jsonEncode(message.data));
  }

  Future<Map<String, dynamic>> loadJsonData() async {
    try {
      final String jsonString =
          await rootBundle.loadString('images/service-acc-file.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return jsonData;
    } catch (e) {
      print('Error loading JSON: $e');
      return {};
    }
  }

  Future getAccessToken() async {
    final Map<String, dynamic> jsonData = await loadJsonData();
    const Scopes = ["https://www.googleapis.com/auth/firebase.messaging"];
    final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(jsonData), Scopes);
    accessToken = client.credentials.accessToken.data;
  }

  ///notification click to navigate particular page
  void fcmMessageHandler(RemoteMessage? message) async {
    if (message != null) {
      // print("fcmMessageHandler ${message.data.toString()}");
      Map<String, String> param = {
        "receiverUserEmail":   message.data['receiverUserEmail'],
        "receiverUserID":  message.data['receiverUserID'],
        "senderId":  message.data['senderId'],
        "image": message.data['image'],
        "username": message.data['username'],
      };
      Get.toNamed(PageConst.chatView, parameters: param);
    }
  }

  initMessaging() async {
    log("Called",name: "initMessaging");
    print("initMessaging Called");
    if (!_initialized) {
      // For iOS request permission first.
      await firebaseMessaging.requestPermission(
          sound: true, badge: true, alert: true);
      // Constant.fcmToken = (await registerNotification())!;
      // log(name: "FCM TOKEN", Constant.fcmToken);
      // print("FCM TOKEN ${Constant.fcmToken}");
      await firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      getNotification();
      configLocalNotification();
      _initialized = true;
    }
  }
}
