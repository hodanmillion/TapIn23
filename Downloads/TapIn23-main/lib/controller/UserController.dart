import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../model/message_chat.dart';

class UserController extends GetxController {
  FirebaseAuth? firebaseAuth = null;
  FirebaseFirestore? fireStore = null;

  RxString userAppLocation = 'Loading Location...'.obs;
  RxString userImage = ''.obs;
  RxString emailP = 'Loading ...'.obs;
  RxString userNameP = 'Loading ...'.obs;
  RxString userImageP = 'Loading ...'.obs;
  RxString isMainUSerP = 'Loading ...'.obs;
  RxString userIdP = 'Loading ...'.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseAuth = FirebaseAuth.instance;
    fireStore = FirebaseFirestore.instance;

    getUserAppLocation(firebaseAuth!.currentUser!.uid);
  }

  void resetUser() {
    firebaseAuth = null;
    fireStore = null;
    userAppLocation = 'Loading Location...'.obs;
    userImage = ''.obs;
    emailP = 'Loading ...'.obs;
    userNameP = 'Loading ...'.obs;
    userImageP = 'Loading ...'.obs;
    isMainUSerP = 'Loading ...'.obs;
    userIdP = 'Loading ...'.obs;
    print('reset');
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