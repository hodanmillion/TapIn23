// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:myapp/pages/home/home.dart';
import 'package:myapp/pages/userProfilePage.dart';

import '../../routes/app_route.dart';
import '../../utils/spHelper.dart';

/// Define a top-level named handler which background/terminated messages will
/// call.
///
/// To verify things are working, check out the native platform logs.
Map<String, dynamic> data = {};
String? sound;
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    onNotificationClick(message!.data);
  });
}

class LocalNotification {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future _onDidReceiveLocalNotification(
      int? id, String? title, String? body, String? payload) async {}
  Future _selectNotification(NotificationResponse? notificationResponse) async {
    var data = jsonDecode(notificationResponse!.payload!);
    Map<String, String> param = {
      "receiverUserEmail":   data['receiverUserEmail'],
      "receiverUserID":  data['receiverUserID'],
      "senderId":  data['senderId'],
    };
    Get.toNamed(PageConst.chatView, parameters: param);
    // onNotificationClick(data);
  }

/*local notification setup*/
  Future<void> configLocalNotification() async {
    if (Platform.isIOS) {
      // set iOS Local notification.
      var initializationSettingsAndroid =
          const AndroidInitializationSettings('');
      // var initializationSettingsAndroid = const AndroidInitializationSettings('ic_launcher');
      /// this is for IOS
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
          onDidReceiveNotificationResponse: (val) => _selectNotification(val));
    } else {
      /// set Android Local notification.
      var initializationSettingsAndroid =
          const AndroidInitializationSettings('');
      var initializationSettingsIOS = DarwinInitializationSettings(
          onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
      var initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse: (val) => _selectNotification(val));
    }
  }

/*handle firebase push notification*/
  getNotification() async {
    // RemoteNotification? notification;
    firebaseMessaging.requestPermission(
        sound: true, badge: true, alert: true, provisional: false);
    await firebaseMessaging.getInitialMessage();
    await firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
// Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('background message ${message.notification!.body}');
      if(Platform.isAndroid){
        showNotification(message);
      }
    return;
  });
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');
      onNotificationClick(message.data);
  });


}
/*genrate token for fcm*/
  tokenGenerator() {
    return firebaseMessaging.getToken();
  }
/*show local notication in device*/
  void showNotification(message) async {
    final List<String> lines = <String>[message.notification.body.toString()];
    final InboxStyleInformation inboxStyleInformation = InboxStyleInformation(
        lines,
        htmlFormatLines: true,
        /*contentTitle: message.notification.title.toString(),
        htmlFormatContentTitle: false,
        summaryText: message.notification.title.toString(),
        htmlFormatSummaryText: false*/
    );
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      Platform.isAndroid ? 'com.example.myapp' : 'com.Tapln.myapp',
      'Tapln',
      playSound: true,
      sound: RawResourceAndroidNotificationSound("${message.notification.android.sound}"),
      enableVibration: true,
      importance: Importance.max,
      priority: Priority.max,
      styleInformation: inboxStyleInformation,
    );
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    flutterLocalNotificationsPlugin.show(
        Random().nextInt(999),
        message.notification.title.toString(),
        message.notification.body.toString(),
        platformChannelSpecifics,
        payload: jsonEncode(message.data));
  }

  Future<void> onNotificationClick(data) async {



    Map<String, String> param = {
      "receiverUserEmail":   data['receiverUserEmail'],
      "receiverUserID":  data['receiverUserID'],
      "senderId":  data['senderId'],
    };
    await Get.toNamed(PageConst.chatView, parameters: param);

  }
}
Future<void> onNotificationClick(data) async {


  Map<String, String> param = {
    "receiverUserEmail":   data['receiverUserEmail'],
    "receiverUserID":  data['receiverUserID'],
    "senderId":  data['senderId'],
  };

  await Get.toNamed(PageConst.chatView, parameters: param);

}


/* Future<void> _showBigTextNotification() async {
    const BigTextStyleInformation bigTextStyleInformation =
        BigTextStyleInformation(
      'Lorem <i>ipsum dolor sit</i> amet, consectetur <b>adipiscing elit</b>, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      htmlFormatBigText: false,
      contentTitle: 'overridden <b>big</b> content title',
      htmlFormatContentTitle: false,
      summaryText: 'summary <i>text</i>',
      htmlFormatSummaryText: false,
    );
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'big text channel id', 'big text channel name',
            channelDescription: 'big text channel description',
            styleInformation: bigTextStyleInformation);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'big text title', 'silent body', platformChannelSpecifics);
  }*/

/*  Future<void> _showInboxNotification() async {
    final List<String> lines = <String>['line <b>1</b>', 'line <i>2</i>'];
    final InboxStyleInformation inboxStyleInformation = InboxStyleInformation(
        lines,
        htmlFormatLines: true,
        contentTitle: 'overridden <b>inbox</b> context title',
        htmlFormatContentTitle: true,
        summaryText: 'summary <i>text</i>',
        htmlFormatSummaryText: true);
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('inbox channel id', 'inboxchannel name',
            channelDescription: 'inbox channel description',
            styleInformation: inboxStyleInformation);
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'inbox title', 'inbox body', platformChannelSpecifics);
  }*/