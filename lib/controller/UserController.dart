import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../model/message_chat.dart';
import '../services/firestore/firestore.dart';

class UserController extends GetxController {
  FirebaseAuth? firebaseAuth = null;
  FirebaseFirestore? fireStore = null;

  RxString userAppLocation = ''.obs;
  RxString userImage = ''.obs;
  RxString emailP = ''.obs;
  RxString userNameP = ''.obs;
  RxString userImageP = ''.obs;
  RxString isMainUSerP = ''.obs;
  RxString userIdP = ''.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseAuth = FirebaseAuth.instance;
    fireStore = FirebaseFirestore.instance;

    userIdP.value = firebaseAuth!.currentUser!.uid;
    getUserAppLocation(firebaseAuth!.currentUser!.uid);
  }

  void resetUser() {
    firebaseAuth = null;
    fireStore = null;
    userAppLocation = ''.obs;
    userImage = ''.obs;
    emailP = ''.obs;
    userNameP = ''.obs;
    userImageP = ''.obs;
    isMainUSerP = ''.obs;
    userIdP = ''.obs;
    print('reset');
  }

  void getUserDataInfo() async {
    try {
      final Map<String, dynamic>? data =
      await FirestoreDB().getUserData(FirebaseAuth.instance.currentUser!.uid);
      print('=======');
      print(data);
      if (data!.isNotEmpty) {

        emailP.value = data["email"];
        userNameP.value = data["username"] ?? data['email'].toString().split("@")[0];
        userImageP.value = data["proImage"]!;
        userIdP.value = FirebaseAuth.instance.currentUser?.uid ?? '';
      }
    } catch (e) {
      print('e: $e');
    }
  }

  Future<void> getUserAppLocation(String userId) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      print("==getUserAppLocationuserid==" + userId);
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final Position position = await Geolocator.getCurrentPosition();
        final double latitude = position.latitude;
        final double longitude = position.longitude;

        final List<Placemark> placemarks =
            await placemarkFromCoordinates(latitude, longitude);
        FirebaseFirestore.instance.collection('users').doc(userId).update({
          'location': GeoPoint(latitude, longitude),
        });
        if (placemarks.isNotEmpty) {
          final Placemark placemark = placemarks.first;
          final String address =
              "${placemark.locality}, ${placemark.administrativeArea}";
          userAppLocation.value = address;
        }
      } else {
        print('Location permission denied');
      }
    } catch (e) {
      print('Error retrieving user location: $e');
      userAppLocation.value = "";
    }
  }

  Future<void> updateProImage(
      {required String userId, required String newImageUrl}) async {
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      await userRef.update({
        'proImage': newImageUrl,
      });
    } catch (e) {
      print('Error updating profile image: $e');
    }
  }
}