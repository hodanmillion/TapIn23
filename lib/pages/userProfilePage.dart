import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/services/firestore/firestore.dart';
import 'package:popover/popover.dart';
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

  final controller = Get.put(UserController());

  @override
  void initState() {
    super.initState();
    controller.getUserDataInfo();
    controller.getUserAppLocation(_auth.currentUser!.uid);


  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Obx(() {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      (controller.userImageP.value != '')
                          ? Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Card(
                                  color: AppColors.imageBorder,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(80)),
                                  elevation: 10,
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: SizedBox(
                                      width: 115.0,
                                      height: 115.0,
                                      child: Obx(
                                        () => InkWell(
                                          onTap: () {
                                            Map<String, String> params = {
                                              "imageUrl":
                                                  controller.userImageP.value ?? '',
                                            };
                                            Get.toNamed(PageConst.imageView,
                                                arguments: params);
                                          },
                                          child: ClipOval(
                                            child: CachedNetworkImage(
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator(),
                                              fit: BoxFit.cover,
                                              imageUrl: controller.userImageP.value.isEmpty ? " " : controller.userImageP.value,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    showUploadOption(context, () async {
                                      Uint8List? imageCode = await handleImageUpload(
                                          ImageSource.gallery);
                                      if (imageCode != null) {
                                        try {
                                          String imageUrl = await StorageMethods()
                                              .uploadImageToStorage(
                                            'profilePics/${controller.userIdP.value}',
                                            imageCode,
                                            false,
                                          );

                                          print("=====image url--" + imageUrl);

                                          controller.userImageP.value = imageUrl;
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
                                          String imageUrl = await StorageMethods()
                                              .uploadImageToStorage(
                                            'profilePics/${controller.userIdP.value}',
                                            imageCode,
                                            false,
                                          );
                                          print('image uploaded: $imageUrl');
                                          controller.userImageP.value = imageUrl;
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
                                )
                              ],
                            )
                          : Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(80)),
                                  elevation: 10,
                                  child: SizedBox(
                                    width: 115.0,
                                    height: 115.0,
                                    child: InkWell(
                                      onTap: () {
                              /*          Map<String, String> params = {
                                          "imageUrl":
                                              controller.userImageP.value ?? '',
                                        };
                                        Get.toNamed(PageConst.imageView,
                                            arguments: params);*/
                                      },
                                      child: const Icon(
                                        Icons.person_outline,
                                        color: Colors.black,
                                        size: 60,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    showUploadOption(context, () async {
                                      Uint8List? imageCode = await handleImageUpload(
                                          ImageSource.gallery);
                                      if (imageCode != null) {
                                        try {
                                          String imageUrl = await StorageMethods()
                                              .uploadImageToStorage(
                                            'profilePics/${controller.userIdP.value}',
                                            imageCode,
                                            false,
                                          );

                                          print("=====image url--" + imageUrl);

                                          controller.userImageP.value = imageUrl;
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
                                          String imageUrl = await StorageMethods()
                                              .uploadImageToStorage(
                                            'profilePics/${controller.userIdP.value}',
                                            imageCode,
                                            false,
                                          );
                                          print('image uploaded: $imageUrl');
                                          controller.userImageP.value = imageUrl;
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
                                )
                              ],
                            ),
                      const SizedBox(height: 10),
                      Text(
                        controller.userNameP.value,
                        style: GoogleFonts.openSans(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                            fontSize: 20,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
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
                                  color: AppColors.primaryColor,
                                  fontSize: 16,
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
                                        bool result = await FirestoreDB().deleteUserData(controller.userIdP.value);

                                        if (result) {

                                          FirebaseFirestore.instance.collection('users').doc(controller.userIdP.value).update({
                                            "UserDeleted": true,
                                          });
                                          // Account deleted successfully
                                          Get.snackbar(
                                            'Account Deleted',
                                            'Your account has been deleted successfully.',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: Colors.green,
                                            colorText: Colors.white,
                                          );


                                          // Delay navigation to give time for the user to see the snackbar
                                          Future.delayed(const Duration(seconds: 2), () {
                                            if (context.mounted) {
                                              // Navigate to the login page or another appropriate page
                                              Navigator.of(context).pop();

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
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(40),
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
                          const SizedBox(
                            height: 20,
                          ),
                          // PopupMenuButton(
                          //   itemBuilder: (context) {
                          //     return List.generate(
                          //         1, (index) => PopupMenuItem(height: 50,child: ListItems()));
                          //   },
                          //   child: Container(
                          //     width: 80,
                          //     height: 40,
                          //     decoration: const BoxDecoration(
                          //       color: Colors.white,
                          //       borderRadius: BorderRadius.all(Radius.circular(5)),
                          //       boxShadow: [
                          //         BoxShadow(color: Colors.black26, blurRadius: 5)
                          //       ],
                          //     ),
                          //     child: const Center(child: Text('Click Me')),
                          //   ),
                          // ),

                          /*Align(
                            alignment: Alignment.topRight,
                            child: PopupMenuButton(

                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              color: Colors.transparent,
                              child: Container(
                                width: 80,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.all(Radius.circular(5)),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black26, blurRadius: 5)
                                  ],
                                ),
                                child: const Center(child: Text('Click Me')),
                              ),
                              itemBuilder: (context) {
                                return List.generate(1, (index) {
                                  return PopupMenuItem(
                                    height: 20,
                                    // padding: EdgeInsets.only(top: 10, right: 15),
                                    value: index,
                                    child: Container(

                                      decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                              bottomRight: Radius.circular(12),
                                              topLeft: Radius.circular(12)),
                                          color: Colors.grey),
                                      child: Padding(
                                        padding: EdgeInsets.all(2),
                                        child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                          Image.asset("images/img.png",width: 35,),
                                          Image.asset("images/img.png",width: 35,),
                                          Image.asset("images/img.png",width: 35,),
                                          Image.asset("images/img.png",width: 35,),
                                          Image.asset("images/img.png",width: 35,),
                                        ]),
                                      ),
                                    ),
                                  );
                                });
                              },
                            ),
                          )*/
                          /*GestureDetector(
                              onLongPressDown: (LongPressDownDetails details) {
                                final globalPosition = details.globalPosition;
                                _longPressPosition = globalPosition;
                                _showPopupMenu();
                              },
                            // onLongPress: () => _showPopupMenu,
                              child:      Container(
                                  height: 50,
                                  width: 50,
                                  child: Text("data",style: TextStyle(fontSize: 24),)),
                          )*/


                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }
  var _longPressPosition;
  Offset _calculatePopupMenuOffset() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final desiredMenuHeight = 50.0;
    final desiredMenuWidth = 100.0;
    final offsetY = _longPressPosition.dy - desiredMenuHeight - kToolbarHeight;
    return Offset(
      _longPressPosition.dx.clamp(0.0, size.width - desiredMenuWidth),
      offsetY.clamp(0.0, size.height - desiredMenuHeight),
    );
  }


  void _showPopupMenu() {
    print("Presssd");
    final offset = _calculatePopupMenuOffset();
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(50, offset.dy, offset.dx, 0.0),

      items: List.generate(1, (index) {
        return PopupMenuItem(
          // padding: EdgeInsets.only(top: 10, right: 15),
          value: index,
          child: Container(

            height: 45,
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                    topLeft: Radius.circular(12)),
                color: Colors.grey),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.add),
                    Icon(Icons.message),
                    Icon(Icons.picture_as_pdf),
                    Icon(Icons.abc_rounded),
                    Icon(Icons.abc_sharp),
                  ]),
            ),
          ),
        );
      }),
    );
  }


  Widget tile({required String title, required String subTitle}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        title,
        style: GoogleFonts.openSans(
          textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.grey,
              letterSpacing: .5),
        ),
      ),
      subtitle: Text(
        subTitle,
        style: GoogleFonts.openSans(
          textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
              fontSize: 16,
              letterSpacing: .5),
        ),
      ),
    );
  }
}

class ListItems extends StatelessWidget {
  const ListItems({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            InkWell(
              onTap: () {
                print("SecondPage");
              },
              child: Container(
                height: 50,
                color: Colors.amber[100],
                child: const Center(child: Text('Entry A')),
              ),
            ),
            const Divider(),
            Container(
              height: 50,
              color: Colors.amber[200],
              child: const Center(child: Text('Entry B')),
            ),
            const Divider(),
            Container(
              height: 50,
              color: Colors.amber[300],
              child: const Center(child: Text('Entry C')),
            ),
          ],
        ),
      ),
    );
  }
}
