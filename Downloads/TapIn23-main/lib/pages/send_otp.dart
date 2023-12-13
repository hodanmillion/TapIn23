import 'package:flutter/material.dart';
import 'package:myapp/components/my_button.dart';
import 'package:myapp/components/my_text_field.dart';
import 'package:myapp/services/auth/auth_service.dart';

class PhoneVerification extends StatefulWidget {
  const PhoneVerification({
    super.key,
  });

  @override
  State<PhoneVerification> createState() => _PhoneVerificationState();
}

class _PhoneVerificationState extends State<PhoneVerification> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void phoneSignIn() async {
    await AuthService().phoneSignIn(context, _phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              //const Text('Please provide your cell number'),
              MyTextField(
                controller: _phoneController,
                hintText: 'Enter Phone number',
                obscureText: false,
              ),
              const SizedBox(
                height: 20,
              ),
              MyButton(onTap: phoneSignIn, text: 'Send OTP')
            ],
          ),
        ),
      ),
    );
  }
}
