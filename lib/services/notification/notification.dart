import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/pages/chatPage.dart';
import 'package:myapp/routes/app_route.dart';
import 'package:myapp/utils/spHelper.dart';
@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(message) async {
  await Firebase.initializeApp();
  log("Handling a background message $message");
}

class FireBaseNoti {
  //create instance of messaging
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _firestoreInstance = FirebaseFirestore.instance;
  final _authInstance = FirebaseAuth.instance;
/*  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();*/

  //initialize notifications

  Future<void> initNotifications() async {
    try {
      print('get token');
      //request permissions

      await _firebaseMessaging.requestPermission(sound: true, badge: true, alert: true, provisional: false);
      print('permisions granted');
      //fetch tokenn for device

      final fcmToken = await _firebaseMessaging.getToken();
      //print token
      print('fcm token: $fcmToken');
      await saveNotificationToken(_authInstance);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true, // Required to display a heads up notification
        badge: true,
        sound: true,
      );

      initPushNotifications();
    } catch (e) {
      print('error with notification: $e');
      print('failed');
    }
  }

  //handle recieved messages
  void handleMessage(
    RemoteMessage? message,
  ) async {
    if (message == null) return;

    print('app opend: ${message.data}');
    // List<String> params = [
    //   message.data['receiverUserEmail'],
    //   message.data['receiverUserID'],
    //   message.data['senderId'],
    // ];
    Map<String, String> param = {
      "receiverUserEmail":   message.data['receiverUserEmail'],
      "receiverUserID":  message.data['receiverUserID'],
      "senderId":  message.data['senderId'],
    };

    await Get.toNamed(PageConst.chatView, parameters: param);
  }

  //init foreground and background settings
  Future initPushNotifications() async {
    // handle when app is teminated
    FirebaseMessaging.onMessage.listen((message) {
      print('message');
      // showNotification(message);
      return;
    });
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    await FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    //attatch event listener for when notifications open

  }

  // void showNotification(message) async {
  //   var androidPlatformChannelSpecifics =  AndroidNotificationDetails(
  //     'com.mcconnect.dermamedspaapp',
  //     'dermamedspa',
  //     playSound: true,
  //     enableVibration: true,
  //     importance: Importance.high,
  //     priority: Priority.high,
  //   );
  //   var iOSPlatformChannelSpecifics =  DarwinNotificationDetails(
  //     presentSound: true,
  //     presentAlert: true,
  //     presentBadge: true,
  //   );
  //   var platformChannelSpecifics = NotificationDetails(
  //       android: androidPlatformChannelSpecifics,
  //       iOS: iOSPlatformChannelSpecifics);
  //
  //   await flutterLocalNotificationsPlugin.show(
  //       0,
  //       message.notification.title.toString(),
  //       message.notification.body.toString(),
  //       platformChannelSpecifics,
  //       payload: jsonEncode(message.data));
  // }


  //save token in user collection
  Future saveNotificationToken(FirebaseAuth authInstance) async {
    String? token = await FirebaseMessaging.instance.getToken();
    final String userId = authInstance.currentUser!.uid;
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    // Check if the user document exists
    final userSnapshot = await userDocRef.get();

    if (userSnapshot.exists) {
      // Check if the 'token' field exists
      if (userSnapshot.data()!.containsKey('token')) {
        print('token exists updating token ');
        // Update the existing 'token'
        await userDocRef.update({'token': token});
      } else {
        // Create the 'token' field and write the token
        print('no token available create token');
        await userDocRef.set({'token': token}, SetOptions(merge: true));
      }
    }
  }



  Future<String> getUserToken(String uid) async {
    CollectionReference userData = _firestoreInstance.collection('users');
    DocumentSnapshot docData = await userData.doc(uid).get();
    if (docData.exists) {
      return docData['token'];
    }
    return '';
  }
}
