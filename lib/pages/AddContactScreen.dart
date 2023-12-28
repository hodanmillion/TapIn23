import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/utils/colors.dart';

class AddContactScreen extends StatefulWidget {
  final Function onFriendRequestSent; // Callback function

  AddContactScreen({required this.onFriendRequestSent});

  @override
  _AddContactScreenState createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _usernameController = TextEditingController();
  String? _searchedUserId;
  String? _searchedEmail;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> searchByUserName() async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: _usernameController.text.toLowerCase())
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final user = querySnapshot.docs.first;
      setState(() {
        _searchedUserId = user.id;
        _searchedEmail = user.data()?['username'];
      });
    } else {
      setState(() {
        _searchedUserId = null;
        _searchedEmail = null;
      });
    }
  }

  Future<void> sendFriendRequest() async {
    final currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!')),
      );
      return;
    }

    if (_searchedUserId == null || _searchedUserId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid user ID!')),
      );
      return;
    }

    bool isAlreadyAContact = await isUserAlreadyAContact(_searchedUserId!);
    if (isAlreadyAContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are already friends with this user!')),
      );
      return;
    }

    // Check for existing friend requests
    final existingRequestsQuerySender = await _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: _searchedUserId)
        .get();

    final existingRequestsQueryReceiver = await _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: _searchedUserId)
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
    await _firestore.collection('friend_requests').add({
      'senderId': currentUserId,
      'receiverId': _searchedUserId,
      'status': 'pending',
    });

    // Notify the parent widget that a request has been sent
    widget.onFriendRequestSent();

    // Pop the screen
    Navigator.pop(context);
  }

  Future<bool> isUserAlreadyAContact(String potentialContactId) async {
    final user = _auth.currentUser;
    if (user != null) {
      final currentUserUid = user.uid;

      // Check in the 'accepted_c' collection
      final existingContactSnapshot = await _firestore
          .collection('accepted_c')
          .where('userId', isEqualTo: currentUserUid)
          .where('contactId', isEqualTo: potentialContactId)
          .get();

      // If a document is found, it means they're already contacts
      return existingContactSnapshot.docs.isNotEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        elevation: 1,
        title: const Text(
          'Add Contact',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Container(
        
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              textInputAction: TextInputAction.search,
              onTap: () => searchByUserName(),
              onSubmitted: (_) => searchByUserName(),
              onEditingComplete: () => searchByUserName(),
              onChanged: (_) => searchByUserName(),
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: const TextStyle(color: AppColors.primaryColor),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: AppColors.primaryColor),
                  onPressed: searchByUserName,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.primaryColor),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (_searchedEmail != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Found: $_searchedEmail',
                      style: const TextStyle(color: AppColors.primaryColor)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: sendFriendRequest,
                    style: ElevatedButton.styleFrom(
                      primary: AppColors.primaryColor,
                      onPrimary: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Send Friend Request'),
                  ),
                ],
              )
            else if (_usernameController.text.isNotEmpty)
              const Text('No user found with this username.',
                  style: TextStyle(color: AppColors.primaryColor)),
          ],
        ),
      ),
    );
  }
}