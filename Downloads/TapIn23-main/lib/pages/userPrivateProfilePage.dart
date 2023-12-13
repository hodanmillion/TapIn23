import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/controller/PrivateChatController.dart';
import '../routes/app_route.dart';

class UserPrivateProfilePage extends StatefulWidget {
  const UserPrivateProfilePage({super.key});

  @override
  State<UserPrivateProfilePage> createState() => _UserPrivateProfilePageState();
}

class _UserPrivateProfilePageState extends State<UserPrivateProfilePage> {
  final prController = Get.find<PrivateChatController>();

  @override
  Widget build(BuildContext context) {
    // Access the parameters
    // final String email = params['email'] ?? '';
    // final String userName = params['userName'] ?? '';
    // final String userImage = params['userImage'] ?? '';
    // final String location = params['location'] ?? '';
    // final String isMainUSer = params['isMainUSer'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                (prController.userImageP.value != '')
                    ? InkWell(
                        onTap: () {
                          Map<String, String> params = {
                            "imageUrl": prController.userImageP.value ?? '',
                          };
                          Get.toNamed(PageConst.imageView, arguments: params);
                        },
                        child: Obx(
                          () => ClipOval(
                            child: CachedNetworkImage(
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              fit: BoxFit.cover,
                              imageUrl: prController.userImageP.value,
                              width: 100.0,
                              height: 100.0,
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 60,
                      ),
                SizedBox(
                  height: 10,
                ),
                Obx(
                  () => Text(
                    prController.userNameP.value,
                    style: GoogleFonts.openSans(
                      textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 25,
                          letterSpacing: .5),
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
                              horizontal: 16, vertical: 8),
                          title: Text(
                            "Display Name",
                            style: GoogleFonts.openSans(
                              textStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.grey,
                                  letterSpacing: .5),
                            ),
                          ),
                          subtitle: Obx(
                            () => Text(
                              prController.userNameP.value,
                              style: GoogleFonts.openSans(
                                textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 25,
                                    letterSpacing: .5),
                              ),
                            ),
                          ),
                        ),
                       
                        Obx(
                          () => tile(
                              title: "Location",
                              subTitle: prController.userLocation.value),
                        ),
                      ],
                    )),
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
  }}