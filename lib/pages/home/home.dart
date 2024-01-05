import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/controller/ContactController.dart';
import 'package:myapp/services/firestore/firestore.dart';
import 'package:myapp/services/notification/notification.dart';
import 'package:myapp/services/notification/notification_service.dart';
import 'package:myapp/utils/colors.dart';
import 'package:provider/provider.dart';
import '../../controller/UserController.dart';
import '../../routes/app_route.dart';
import '../../services/auth/auth_service.dart';
import '../../services/notification/notification2.dart';
import '../AddContactScreen.dart';
import '../contacts_page.dart';
import '../past_chats_page.dart';
import '../request/requestPage.dart';
import '../userProfilePage.dart';

class HomePageNew extends StatefulWidget {
  @override
  _HomePageNewState createState() => _HomePageNewState();
}

class _HomePageNewState extends State<HomePageNew> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  List<DocumentSnapshot> friendRequests = [];
  final controller = Get.put(UserController());
  final  contactController = Get.put(ContactsController());

  String? proImage;
  String email = '';
  String username = '';
  String location = '';

  int _selectedIndex = 0;
  final List<Widget> _widgetOptions = [
    ContactsPage(),
    const RequestPage(),
    PastChatListPage(),
    const UserProfilePage(),
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
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        onPressed: navigateToAddContact,
        icon: const Icon(Icons.person_add, color: AppColors.primaryColor),
        tooltip: "Add Contact",
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _selectedIndex == 0
              ? const Text(
                  'Private Chats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                )
              : _selectedIndex == 1
                  ? const Text(
                      'Friend Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    )
                  : _selectedIndex == 2
                      ? const Text(
                          'Public Chats',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        )
                      : const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
        ],
      ),
      actions: [

        IconButton(
          onPressed: signOut,
          icon: const Icon(Icons.logout, color: AppColors.primaryColor),
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
                child: CircleAvatar(
                  radius: 20,
                  child: Container(
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
              ),
            )
          : CircleAvatar(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              radius: 20,
              child: Text(
                userInitial.toUpperCase(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
    );
  }


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
          username = data['username'] ?? data['email'].toString().split("@")[0];
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
      controller.userImageP.value = "";
      controller.userNameP.value = "";
      controller.userImageP.value = "";
      controller.isMainUSerP.value = "";
      controller.userIdP.value = "";
      print('sign out');
    } catch (error) {
      print("Failed to sign out: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFriendRequests();
    getUserDataInfo();
    AppNotification().initMessaging();
    contactController.fetchAcceptedContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey, width: 1.0)),

      ),
        child: BottomNavigationBar(

          showUnselectedLabels: false,
          showSelectedLabels: false,
          backgroundColor: Colors.grey.shade100,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.contact_page,size: 22),
              label: 'Contact',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_add_rounded,size: 22),
              label: 'Request',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,

          selectedItemColor: const Color(0xff24786D),
          // Change the selected icon and text color to green
          unselectedItemColor: const Color(
              0xff797C7B), // Change the unselected icon and text color to grey
        ),
      ),
    );
  }
}
