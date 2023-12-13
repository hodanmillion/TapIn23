import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/components/my_button.dart';
import 'package:myapp/components/my_text_field.dart';
import 'package:myapp/services/auth/auth_service.dart';
import 'package:myapp/services/firestore/firestore.dart';
import 'package:myapp/utils/image_select.dart';
import 'package:myapp/utils/upload_image_dialogue.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';

class Register extends StatefulWidget {
  final void Function()? onTap;

  const Register({super.key, required this.onTap});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  // text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();
  final usernameController = TextEditingController();
  Uint8List? proImage;
  bool isLoading = false;

  void updateIsLoading() {
    print('before: $isLoading');
    setState(() {
      isLoading = !isLoading;
    });
    print('after: $isLoading');
  }

  Future<bool> signup() async {
    if (passwordController.text != confirmpasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords don't match!")));
      return false;
    }
    final authService = Provider.of<AuthService>(context, listen: false);

    if (usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('please enter username')));

      return false;
    } else {
      bool checkUserIsPresent =
          await FirestoreDB().isUserNameUnique(usernameController.text);
      if (!checkUserIsPresent) {
        print('user is present');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'username ${usernameController.text} not available \nTry a another username')));
        return false;
      } else {
        print('no userfound');
      }
    }

    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('please enter email')));
      return false;
    }

    if (proImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('please load profile pic')));
      return false;
    }

    if (passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('please enter a password')));
      return false;
    }

    print('image url: $proImage');

    try {
      await authService.signUpWithEmailandPassword(
        emailController.text,
        passwordController.text,
        proImage,
        usernameController.text,
      );

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
      return false;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmpasswordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // Wrap the Column with a SingleChildScrollView
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        proImage == null
                            ? Image.asset(
                                'images/logo2.png',
                                width: 100,
                                height: 100,
                              )
                            : ClipOval(
                                child: Image.memory(
                                  proImage!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: IconButton(
                              icon: const Icon(
                                Icons.photo_camera,
                                size: 30,
                                color: AppColors.primaryColor,
                              ),
                              onPressed: () {
                                print('profile image');
                                showUploadOption(context, () async {
                                  //upload image from gallery
                                  Uint8List? image = await handleImageUpload(
                                      ImageSource.gallery);
                                  if (image != null) {
                                    setState(() {
                                      proImage = image;
                                    });
                                  }
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                }, () {}, false);
                              }),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SvgPicture.asset(
                    'images/signup_logo.svg', // Replace with the actual path to your logo image
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Connecting People through Location",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      textStyle: const TextStyle(
                          color: AppColors.primaryColor, letterSpacing: .5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  MyTextField(
                    controller: usernameController,
                    hintText: 'Username',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: confirmpasswordController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 25),
                  MyButton(onTap: signup, text: 'Sign Up'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already a member?',
                        style: GoogleFonts.openSans(
                          textStyle: const TextStyle(
                              color: AppColors.primaryColor, letterSpacing: .5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Text(
                          'Log In!',
                          style: GoogleFonts.openSans(
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                                letterSpacing: .5),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
