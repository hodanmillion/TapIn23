import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/routes/app_route.dart';

class FireBaseNoti {
  //create instance of messaging
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _firestoreInstance = FirebaseFirestore.instance;
  final _authInstance = FirebaseAuth.instance;

  //initialize notifications

  Future<void> initNotifications() async {
    try {
      print('get token');
      //request permissions

      await _firebaseMessaging.requestPermission();
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
    Map<String, String> params = {
      "receiverUserEmail": message.data['reciverUserEmail'],
      "senderId": message.data['reciverUserID'],
      "receiverUserID": message.data['senderId'],
    };
    Get.toNamed(PageConst.chatView, parameters: params);
  }

  //init foreground and background settings
  Future initPushNotifications() async {
    // handle when app is teminated
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    //attatch event listener for when notifications open
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    FirebaseMessaging.onMessage.listen((event) {
      print('listening');
      print(event);
    });
  }

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

  Future<void> sendNotification(
    String token,
    String body,
    String title,
    Map<String, dynamic> data,
  ) async {
    print('sending notification');
    try {
      final res = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAAk2pWUzU:APA91bFBosyFQlGHRK1aHE-D9P2xJOTHjd5bM0MRIjyOPqRsH0uqJqCS7rW4wfYN4pz_tB_JEg-FrxIiowuYCaG3V9cjaUICGkmfvTEEWy_6i9EEnVLZL6LSrjhBF-EOFLCL7tpQeNWe'
        },
        body: jsonEncode({
          'data': data,
          "to": token,
          "notification": {
            "title": title,
            "body": body,
          }
        }),
      );
      print(res.body);
      print('noti send succ');
    } catch (e) {
      print("Error sending notification: $e");
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
