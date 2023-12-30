import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/controller/PrivateChatController.dart';
import 'package:myapp/controller/past_chat_controller.dart';
import 'package:myapp/utils/colors.dart';
import '../routes/app_route.dart';

class PublicChatProfilePage extends StatefulWidget {
  final String? email;
  final String? name;
  final String? image;
  final String? userId;
  final Function? onFriendRequestSent;
  const PublicChatProfilePage({super.key, this.email, this.name, this.image, this.userId, this.onFriendRequestSent});

  @override
  State<PublicChatProfilePage> createState() => _PublicChatProfilePageState();
}

class _PublicChatProfilePageState extends State<PublicChatProfilePage> {

  var receiverUserID = "".obs;
  RxString userLocation = ''.obs;

  RxString emailP = ''.obs;
  RxString userNameP = ''.obs;
  RxString userImageP = ''.obs;
  RxBool answerCooldownInProgress = true.obs;

  final FirebaseAuth auth = FirebaseAuth.instance;


  RxList<DocumentSnapshot> acceptedContacts = RxList<DocumentSnapshot>();
  RxList<String> acceptedContactId = RxList<String>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchAcceptedContacts().whenComplete(() {
      print(acceptedContacts);
    });
    answerCooldownInProgress.value = true;

    // getUserLocation(receiverUserID.value);
    emailP.value = widget.email!;
    userNameP.value = widget.name!;
    userImageP.value = widget.image!;
    receiverUserID.value = widget.userId!;
  }
  @override
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
      body: Obx(() {
        bool isfriend = acceptedContacts.value.where((element) => element.id == widget.userId).isEmpty;
          return SafeArea(
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
                    (userImageP.value != '')
                        ? InkWell(
                      onTap: () {
                        Map<String, String> params = {
                          "imageUrl": userImageP.value ?? '',
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
                              imageUrl: userImageP.value,
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
                        userNameP.value,
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
                                userNameP.value,
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

                            stream: userLocationStreem(receiverUserID.value),
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
                                      subTitle: userLocation.value),
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
                  
                  isfriend ? ElevatedButton(
                    onPressed: sendFriendRequest,
                    style: ElevatedButton.styleFrom(
                      primary: AppColors.primaryColor,
                      onPrimary: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Send Friend Request'),
                  ) : const SizedBox(),              ],
            ),
          );
        }
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
      userLocation.value = address;
      print(userLocation.value);
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userLocationStreem(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots();
  }


  Future<void> sendFriendRequest() async {
    final currentUserId = auth.currentUser?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!')),
      );
      return;
    }

    if (widget.userId == null || widget.userId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid user ID!')),
      );
      return;
    }

    bool isAlreadyAContact = await isUserAlreadyAContact(widget.userId!);
    if (isAlreadyAContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are already friends with this user!')),
      );
      return;
    }

    // Check for existing friend requests
    final existingRequestsQuerySender = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: widget.userId)
        .get();

    final existingRequestsQueryReceiver = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('senderId', isEqualTo: widget.userId)
        .where('receiverId', isEqualTo: currentUserId)
        .get();

    if (existingRequestsQuerySender.docs.isNotEmpty ||
        existingRequestsQueryReceiver.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A request already exists with this user!')),
      );
      return;
    }

    // Send a new friend request
    await FirebaseFirestore.instance.collection('friend_requests').add({
      'senderId': currentUserId,
      'receiverId': widget.userId,
      'status': 'pending',
    });

    // Notify the parent widget that a request has been sent
    widget.onFriendRequestSent!();

    // Pop the screen
    Navigator.pop(context);
  }

  Future<bool> isUserAlreadyAContact(String potentialContactId) async {
    final user = auth.currentUser;
    if (user != null) {
      final currentUserUid = user.uid;

      // Check in the 'accepted_c' collection
      final existingContactSnapshot = await FirebaseFirestore.instance
          .collection('accepted_c')
          .where('userId', isEqualTo: currentUserUid)
          .where('contactId', isEqualTo: potentialContactId)
          .get();

      // If a document is found, it means they're already contacts
      return existingContactSnapshot.docs.isNotEmpty;
    }
    return false;
  }


  Future<void> fetchAcceptedContacts() async {
    try {
      final user = auth.currentUser;
      print(user);
      if (user != null) {
        final currentUserUid = user.uid;
        final contactsQuery = await FirebaseFirestore.instance
            .collection('accepted_c')
            .doc(currentUserUid) // Change this line
            .collection('contacts'); // Change this line

        //    final contactDocs = contactsQuery.docs;
        // acceptedContacts.clear();
        var message = contactsQuery.snapshots().map((querySnap) {
          return querySnap.docs.map((docSnap) => docSnap).toList();
        });
        acceptedContacts.bindStream(message);



        print("===currentUserUid==" + currentUserUid);

        print("===contacts==" + acceptedContacts.length.toString());
        // Extract contact names and store them in acceptedContactNames.
        // acceptedContactNames.bindStream(contactDocs.map<String>((doc) {
        //   final data = doc.data() as Map<String, dynamic>;
        //   return data['contactName'].toString(); // Explicitly cast to String.
        // }) as Stream<List<String>>);
      } else {
        // Handle the case where the user is not logged in
        print("User is not logged in.");
      }
    } catch (error) {
      // Handle any other errors that might occur during data retrieval
      print("Failed to fetch accepted contacts: $error");
    }
  }

}