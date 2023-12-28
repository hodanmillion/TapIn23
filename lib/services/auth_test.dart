import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/pages/auto_generated_chat_page.dart';
import 'package:myapp/pages/home_page.dart';
import 'package:myapp/pages/verify_email.dart';
import 'package:myapp/services/auth/logreg.dart';

import '../pages/home/home.dart';

class AuthG extends StatelessWidget {
  const AuthG({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // user is logged in
            if (snapshot.hasData && snapshot.data!.uid.isNotEmpty) {
              if (snapshot.data!.emailVerified == true) {
                //  return const HomePage();
                return HomePageNew();
              } else {
                return const VerifyEmail();
              }
              //return const VerifyEmail();
            }

            //user is not logged in
            else {
              return const LoginOrReg();
            }
          }),
    );
  }
}
