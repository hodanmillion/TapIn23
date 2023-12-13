import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/pages/home/home.dart';
import '../utils/colors.dart';

class VerifyEmail extends StatefulWidget {
  const VerifyEmail({super.key});

  @override
  State<VerifyEmail> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  bool _isVerified = false;
  Timer? timer;
  bool canResend = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _isVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    if (!_isVerified) {
      print('checking verification');
      sendEmailVerification();
      timer = Timer.periodic(
        Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    timer?.cancel();
    super.dispose();
  }

  Future sendEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
      setState(() {
        canResend = false;
      });
      await Future.delayed(const Duration(seconds: 4));
      setState(() {
        canResend = true;
      });
    } catch (e) {
      print('error occured');
      print('error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    setState(() {
      _isVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (_isVerified) {
      timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerified) {
      return HomePageNew();
    } else {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Email Verification'),
        ),
        body: Container(
          margin: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Verify Your Email',
                style: GoogleFonts.openSans(
                  textStyle: const TextStyle(
                      fontSize: 24.0,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: .5),
                ),
              ),
              SizedBox(height: 20.0),
              Text(
                'A verification link has been sent to your email address. Please click the link to verify your email.',
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  textStyle: const TextStyle(
                      fontSize: 16.0,
                      color: AppColors.primaryColor,
                      letterSpacing: .5),
                ),
              ),
              const SizedBox(height: 40.0),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    AppColors.primaryColor,
                  ),
                ),
                onPressed: canResend ? sendEmailVerification : () {},
                child: const Text('Resend email verification'),
              ),
              const SizedBox(height: 10.0),
              TextButton(
                onPressed: () {
                  print('cancel verifiy');

                  FirebaseAuth.instance.signOut();
                  //TODO clean up data in firestore db
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              SizedBox(height: 10.0),
            ],
          ),
        ),
      );
    }
  }
}