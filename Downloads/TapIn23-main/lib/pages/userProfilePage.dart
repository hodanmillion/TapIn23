import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/services/firestore/firestore.dart';
import '../controller/UserController.dart';
import '../routes/app_route.dart';
import '../services/storage/fire_storage.dart';
import '../utils/colors.dart';
import '../utils/image_select.dart';
import '../utils/upload_image_dialogue.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final controller = Get.find<UserController>();

  @override
  void initState() {
    super.initState();

final user = _auth.currentUser;
if (user != null) {
  controller.getUserAppLocation(user.uid);
}
  }
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(height: 10),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 10),
                Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          Column(
            children: [
              (controller.emailP.value != '')
                  ? Stack(
                      children: [
                        Obx(
                          () => InkWell(
                            onTap: () {
                              Map<String, String> params = {
                                "imageUrl": controller.userImageP.value ?? '',
                              };
                              Get.toNamed(PageConst.imageView, arguments: params);
                            },
                            child: ClipOval(
                              child: CachedNetworkImage(
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                fit: BoxFit.cover,
                                imageUrl: controller.userImage.value,
                                width: 100.0,
                                height: 100.0,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              showUploadOption(context, () async {
                                Uint8List? imageCode =
                                    await handleImageUpload(ImageSource.gallery);
                                if (imageCode != null) {
                                  try {
                                    String imageUrl =
                                        await StorageMethods().uploadImageToStorage(
                                      'profilePics/${controller.userIdP.value}',
                                      imageCode,
                                      false,
                                    );

                                    print("=====image url--" + imageUrl);

                                    controller.userImage.value = imageUrl;
                                    await controller.updateProImage(
                                      userId: controller.userIdP.value,
                                      newImageUrl: imageUrl,
                                    );
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  } catch (e) {
                                    print('error occurred: $e');
                                  }
                                }
                              }, () async {
                                Uint8List? imageCode =
                                    await handleImageUpload(ImageSource.camera);
                                if (imageCode != null) {
                                  try {
                                    String imageUrl =
                                        await StorageMethods().uploadImageToStorage(
                                      'profilePics/${controller.userIdP.value}',
                                      imageCode,
                                      false,
                                    );
                                    print('image uploaded: $imageUrl');
                                    controller.userImage.value = imageUrl;
                                    await controller.updateProImage(
                                      userId: controller.userIdP.value,
                                      newImageUrl: imageUrl,
                                    );

                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  } catch (e) {
                                    print('error occurred: $e');
                                  }
                                }
                              }, true);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8.0),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 24.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 60,
                    ),
              const SizedBox(height: 10),
              Text(
                controller.userNameP.value,
                style: GoogleFonts.openSans(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 25,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              color: Colors.black,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(40),
                    topLeft: Radius.circular(40),
                  ),
                  border: Border.all(
                    width: 3,
                    color: Colors.white,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        "Display Name",
                        style: GoogleFonts.openSans(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                      subtitle: Text(
                        controller.userNameP.value,
                        style: GoogleFonts.openSans(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 25,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                    ),
                    tile(
                      title: "Email Address",
                      subTitle: controller.emailP.value,
                    ),
                    Obx(
                      () => tile(
                        title: "Location",
                        subTitle: controller.userAppLocation.value,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        print('delete account');
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Deleting Account!'),
                            content: const Text(
                              'Are you sure you want to delete your account?',
                            ),
                            actionsAlignment: MainAxisAlignment.spaceEvenly,
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  print('Delete account logic');
                                  bool result = await FirestoreDB()
                                      .deleteUserData(controller.userIdP.value);

                                  if (result) {
                                    // Account deleted successfully
                                    Get.snackbar(
                                      'Account Deleted',
                                      'Your account has been deleted successfully.',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.green,
                                      colorText: Colors.white,
                                    );

                                    // Delay navigation to give time for the user to see the snackbar
                                    Future.delayed(Duration(seconds: 2), () {
                                      if (context.mounted) {
                                        // Navigate to the login page or another appropriate page
                                        Get.offAllNamed(PageConst.login);
                                      }
                                    });
                                  } else {
                                    // Failed to delete account
                                    Get.snackbar(
                                      'Error',
                                      'Failed to delete account. Please try again later.',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  }
                                },
                                style: TextButton.styleFrom(
                                  primary: Colors.white,
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  primary: Colors.black,
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Delete Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}



  Widget tile({required String title, required String subTitle}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        title,
        style: GoogleFonts.openSans(
          textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.grey,
              letterSpacing: .5),
        ),
      ),
      subtitle: Text(
        subTitle,
        style: GoogleFonts.openSans(
          textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 18,
              letterSpacing: .5),
        ),
      ),
    );
  }
}