import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/controller/PrivateChatController.dart';
import 'package:myapp/utils/colors.dart';
import '../routes/app_route.dart';

class UserPrivateProfilePage extends StatefulWidget {
  const UserPrivateProfilePage({super.key});

  @override
  State<UserPrivateProfilePage> createState() => _UserPrivateProfilePageState();
}

class _UserPrivateProfilePageState extends State<UserPrivateProfilePage> {
  final prController = Get.find<PrivateChatController>();

  @override
  void initState() {
    prController.getUserLocation(prController.receiverUserID.value);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Access the parameters
    // final String email = params['email'] ?? '';
    // final String userName = params['userName'] ?? '';
    // final String userImage = params['userImage'] ?? '';
    // final String location = params['location'] ?? '';
    // final String isMainUSer = params['isMainUSer'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  Icon(
                    Icons.arrow_back,
                    color: Colors.black,
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
                          () => Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            elevation: 10,
                            child: ClipOval(

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
                        ),
                      )
                    : Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  elevation: 6,
                      child: Container(
                  width: 100.0,
                        height: 100.0,
                        child: const Icon(
                            Icons.person_outline,
                            color: Colors.black,
                          size: 60,
                          ),
                      ),
                    ),
                const SizedBox(
                  height: 10,
                ),
                Obx(
                  () => Text(
                    prController.userNameP.value,
                    style: GoogleFonts.openSans(
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
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
                            textStyle: const TextStyle(
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
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                  fontSize: 16,
                                  letterSpacing: .5),
                            ),
                          ),
                        ),
                      ),

                      StreamBuilder(

                        stream: prController.userLocationStreem(prController.receiverUserID.value),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return const Center(
                              child: Text('Failed to fetch data'),
                            );
                          } else if (snapshot.data != null) {
                            // Check if snapshot.data is not null and is of the expected type
                            Map<String, dynamic> userData =
                            snapshot.data!.data() as Map<String, dynamic>;
                            // prController.userLocation.value = userData['location'] ?? '';
                            GeoPoint? location = userData['location'] as GeoPoint?;
                            final double latitude = location!.latitude;
                            final double longitude = location.longitude;
                            setPlaceMark(latitude,longitude);

                            // Now you can safely access userData properties
                            return Obx(
                                  () => tile(
                                      title: "Location",
                                      subTitle: prController.userLocation.value),
                            );
                          } else {
                            // Handle the case when snapshot.data is null or of unexpected type
                            return const Center(
                              child: Text('Account Deleted'),
                            );
                          }
                        },
                      ),
                    /*  Obx(
                        () => tile(
                            title: "Location",
                            subTitle: prController.userLocation.value),
                      ),*/
                    ],
                  )),
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

  Future<void> setPlaceMark(double latitude, double longitude) async {
    final List<Placemark> placemarks =
        await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      final Placemark placemark = placemarks.first;
      final String address =
          "${placemark.locality}, ${placemark.administrativeArea}";
      prController.userLocation.value = address;
      print(prController.userLocation.value);
    }
  }}