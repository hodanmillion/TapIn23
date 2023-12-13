import 'package:flutter/material.dart';
import 'package:myapp/pages/login.dart';
import 'package:myapp/pages/register.dart';


class LoginOrReg extends StatefulWidget {
  const LoginOrReg({super.key});

  @override
  State<LoginOrReg> createState() => _LoginOrRegState();

}

class _LoginOrRegState extends State<LoginOrReg> {
  //show login screen
  bool showLoginPage = true;

  // toggle between login | register 
  void togglePages(){
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }
  @override
  Widget build(BuildContext context) {
    if (showLoginPage){
      return Login(onTap: togglePages); 
    }
    else {
      return Register(onTap: togglePages);
    }
  }
}