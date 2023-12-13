import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:myapp/pages/home_page.dart';
import 'package:myapp/services/notification/notification.dart';
import 'package:myapp/services/storage/fire_storage.dart';
import 'package:myapp/utils/show_otp.dart';

class AuthService extends ChangeNotifier {
  //handle all different methods for auth
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  //instance of firestone
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //instance of storage

  final FirebaseStorage _storage = FirebaseStorage.instance;

  //sign user in

  Future<UserCredential> signInWithEmailandPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      //add new doc for user in users collections if doesn't exist
      _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
      }, SetOptions(merge: true));
      await FireBaseNoti().saveNotificationToken(_firebaseAuth);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //create new user
  Future<UserCredential> signUpWithEmailandPassword(
    String email,
    password,
    Uint8List? image,
    String userName,
  ) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      //attempt to load image and get imageurl
      if (image != null &&
          userName.isNotEmpty &&
          userCredential.user!.uid.isNotEmpty) {
        String imageUrl = await StorageMethods().uploadImageToStorage(
          'profilePics/${_firebaseAuth.currentUser!.uid}',
          image,
          false,
        );
        _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'username': userName,
          'proImage': imageUrl,
        });
      }

      //store username and image url as well

      // after creating user, create new doc for user in users collection

      FireBaseNoti().saveNotificationToken(_firebaseAuth);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }


  
  // sign out

  Future<void> signOut() async {
    return await _firebaseAuth.signOut();
  }

  //sign in with phone
  Future<void> phoneSignIn(BuildContext context, String phoneNumber) async {
    TextEditingController codeController = TextEditingController();
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        //this function works only on android
        await _firebaseAuth.signInWithCredential(credential);
        print('phone otp completed');
      },
      verificationFailed: (error) {
        print('error: $error');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message!)));
      },
      codeSent: ((String verficationID, int? resendToken) async {
        //helps with IOS and android if android does not support auto fill otp
        showOTPDialog(
          context: context,
          codeController: codeController,
          onPressed: () async {
            PhoneAuthCredential credential = PhoneAuthProvider.credential(
              verificationId: verficationID,
              smsCode: codeController.text.trim(),
            );

            await _firebaseAuth.signInWithCredential(credential);
            print('phone otp completed with code');
            if (context.mounted) {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const HomePage()));
            }
          },
        );
      }),
      codeAutoRetrievalTimeout: (String verficationId) {
        //auto resolution timed out
        debugPrint('time out');
      },
    );
  }

  void sendVerifyEmail() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } catch (e) {
      print(e);
    }
  }

    Future<void> resetPassword(String email) async {
    // Implement password reset logic here (e.g., send a reset email)
    // This is just a placeholder; replace it with the actual logic.

    // Example using Firebase Authentication
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      // Handle error, show error message, etc.
      throw Exception('Error sending password reset email: $e');
    }
  }

}
