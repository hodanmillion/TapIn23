import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/controller/ContactController.dart';
import 'package:myapp/controller/chat_controller.dart';
import 'package:myapp/services/chat/chat_service.dart';
import 'package:myapp/services/firestore/firestore.dart';
import 'package:myapp/utils/colors.dart';
import 'package:provider/provider.dart';

import '../../controller/UserController.dart';
import '../../routes/app_route.dart';
import '../../services/auth/auth_service.dart';
import '../AddContactScreen.dart';
import '../contacts_page.dart';
import '../past_chats_page.dart';
import '../request/requestPage.dart';

class HomePageNew extends StatefulWidget {
  @override
  _HomePageNewState createState() => _HomePageNewState();
}

class _HomePageNewState extends State<HomePageNew> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  List<DocumentSnapshot> friendRequests = [];
  final controller = Get.find<UserController>();
  String? proImage;
  String email = '';
  String username = '';
  String location = '';

  int _selectedIndex = 0;
  final List<Widget> _widgetOptions = [
    ContactsPage(),
    const RequestPage(),
    PastChatListPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    // precacheImage(, context);

    super.didChangeDependencies();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        onPressed: navigateToAddContact,
        icon: Icon(Icons.person_add, color: Colors.white),
        tooltip: "Add Contact",
      ),
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'TapIn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        _proIcon(),
        SizedBox(width: 4),
        IconButton(
          onPressed: signOut,
          icon: Icon(Icons.logout, color: Colors.white),
        ),
      ],
    );
  }

  Widget _proIcon() {
    String? userEmail = _auth.currentUser?.email ?? "Unknown User";
    String userInitial = userEmail.isNotEmpty ? userEmail[0] : "?";
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          PageConst.userProfilePage,
        );
      },
      child: proImage != null
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Tooltip(
                message: userEmail,
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FirebaseImageProvider(FirebaseUrl(proImage!)),
                    ),
                  ),
                ),
              ),
            )
          : CircleAvatar(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              radius: 30,
              child: Text(
                userInitial.toUpperCase(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
    );
  }

  // Widget _profileIcon() {
  //   String? userEmail = _auth.currentUser?.email ?? "Unknown User";
  //   String userInitial = userEmail.isNotEmpty ? userEmail[0] : "?";

  //   return GestureDetector(
  //     onTap: () async {
  //       String email = '';
  //       String username = '';
  //       String proImage = '';
  //       String location = '';

  //       try {
  //         final user = _auth.currentUser;

  //         DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
  //             .collection("users")
  //             .doc(user!.uid)
  //             .get();

  //         if (documentSnapshot.exists) {
  //           // The document exists, and you can access its data.
  //           Map<String, dynamic> data =
  //               documentSnapshot.data() as Map<String, dynamic>;
  //           // Access specific fields in the data.
  //           email = data['email'];
  //           username = data['username'];
  //           proImage = data['proImage'];
  //           location = controller.userAppLocation.value;
  //           controller.userImage.value = proImage;
  //           print("locasddstion $location");
  //           // Use the data as needed.
  //         } else {
  //           // The document doesn't exist.
  //           print('Document does not exist.');
  //         }
  //       } catch (e) {
  //         print('Error querying document: $e');
  //       }

  //       // Map<String, String> params = {
  //       //   "email": email ?? '',
  //       //   "userName": username ?? '',
  //       //   "userImage": proImage ?? '',
  //       //   "location": location.toString() ?? '',
  //       //   "userId": _auth.currentUser?.uid ?? '',
  //       //   "isMainUSer": "yes",
  //       // };

  //       controller.emailP!.value = email ?? '';
  //       controller.userNameP!.value = username ?? '';
  //       controller.userImageP!.value = proImage ?? '';
  //       controller.userIdP!.value = _auth.currentUser?.uid ?? '';

  //       Get.toNamed(
  //         PageConst.userProfilePage,
  //       );
  //     },
  //     child: FutureBuilder(
  //         future: FirestoreDB().getUserData(_auth.currentUser!.uid),
  //         builder: (context, data) {
  //           if (data.connectionState == ConnectionState.waiting) {
  //             return Text(userInitial);
  //           } else if (data.hasError) {
  //             return CircleAvatar(
  //               backgroundColor: Colors.blue,
  //               foregroundColor: Colors.white,
  //               radius: 30,
  //               child: Text(
  //                 userInitial.toUpperCase(),
  //                 style: TextStyle(fontSize: 24),
  //               ),
  //             );
  //           }
  //           return Padding(
  //             padding: const EdgeInsets.all(8.0),
  //             child: Tooltip(
  //               message: userEmail,
  //               child: Container(
  //                 width: 45,
  //                 height: 45,
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey.shade200,
  //                   borderRadius: BorderRadius.circular(25),
  //                   image: DecorationImage(
  //                     fit: BoxFit.cover,
  //                     image: FirebaseImageProvider(
  //                         FirebaseUrl(data.data!['proImage'])),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           );
  //         }),
  //   );
  // }

  void navigateToAddContact() {
    // Navigate to the AddContactScreen and pass the callback
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddContactScreen(
          onFriendRequestSent: onFriendRequestSent, // Pass the callback here
        ),
      ),
    );
  }

  void onFriendRequestSent() {
    // Implement the logic to handle the friend request sent.
    // You can update the UI or perform any necessary actions here.
    // For example, you can refresh the friend requests tab.
    fetchFriendRequests();
  }

  void getUserDataInfo() async {
    try {
      final Map<String, dynamic>? data =
          await FirestoreDB().getUserData(_auth.currentUser!.uid);
      print('=======');
      print(data);
      if (data!.isNotEmpty) {
        setState(() {
          proImage = data['proImage'];
          email = data['email'];
          username = data['username'];
          proImage = data['proImage'];
          location = controller.userAppLocation.value;
          controller.userImage.value = proImage!;
        });
        controller.emailP.value = email;
        controller.userNameP.value = username;
        controller.userImageP.value = proImage!;
        controller.userIdP.value = _auth.currentUser?.uid ?? '';
      }
    } catch (e) {
      print('e: $e');
    }
  }

  Future<void> fetchFriendRequests() async {
    try {
      setState(() {
        isLoading = true;
      });
      final user = _auth.currentUser;
      if (user != null) {
        final currentUserUid = user.uid;
        final friendRequestsQuery = await FirebaseFirestore.instance
            .collection('friend_requests')
            .where('receiverId', isEqualTo: currentUserUid)
            .get();

        setState(() {
          friendRequests = friendRequestsQuery.docs;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Failed to fetch friend requests: $error");
    }
  }

  @override
  void signOut() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await FirebaseAuth.instance.signOut();

      print('sign out');
      // Get.find<UserController>().dispose();
      // Get.find<ContactsController>().dispose();

      // Get.find<ChatController>().dispose();
    } catch (error) {
      print("Failed to sign out: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFriendRequests();
    getUserDataInfo();
    //  controller.requestLocationPermission(_auth!.currentUser!.uid);

    // Update user's location when the app starts
    //final user = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: _buildAppBar(),
        body: _widgetOptions[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Contact',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_add_rounded),
              label: 'Request',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,

          selectedItemColor: Color(0xff24786D),
          // Change the selected icon and text color to green
          unselectedItemColor: Color(
              0xff797C7B), // Change the unselected icon and text color to grey
        ),
      ),
    );
  }
}
