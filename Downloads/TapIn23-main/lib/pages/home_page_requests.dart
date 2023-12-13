import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/colors.dart';

class HomePageRequests extends StatefulWidget {
  final List<DocumentSnapshot> friendRequests;
  final bool isLoading;
  final Function(DocumentSnapshot) onRequestAccepted;
  final Function() parentRefresh;

  HomePageRequests({
    required this.friendRequests,
    required this.isLoading,
    required this.onRequestAccepted,
    required this.parentRefresh,
  });

  @override
  State<HomePageRequests> createState() => _HomePageRequestsState();
}

class _HomePageRequestsState extends State<HomePageRequests> {
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData;
      }
      return null;
    } catch (e) {
      print('Error fetching user email: $e');
      return null;
    }
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot request) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final data = request.data() as Map<String, dynamic>;
    final senderId = data['senderId'];
    final receiverId = data['receiverId'];
    final status = data['status'];
    final requestId = request.id;

    if (status == 'pending' && receiverId == _auth.currentUser!.uid) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(senderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListTile(title: Text('Loading...'));
          }
          if (snapshot.hasError) {
            return ListTile(title: Text('Error: ${snapshot.error.toString()}'));
          }

          final senderData = snapshot.data ?? {};
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16.0),
              title: Text(
                'Username: ${senderData["username"]}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: $status',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Email: ${senderData["email"]}',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () async {
                      // Remove the friend request from 'friend_requests' collection.
                      await _firestore.collection('friend_requests').doc(requestId).delete();

                      // Notify the parent widget to refresh Requests tab.
                      widget.parentRefresh();

                      widget.onRequestAccepted(request);
                    },
                    child: Text('Accept'),
                    style: TextButton.styleFrom(
                      primary: Colors.white, // Text color
                      backgroundColor: AppColors.primaryColor, // Background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  TextButton(
                    onPressed: () async {
                      // Remove the friend request from 'friend_requests' collection.
                      await _firestore.collection('friend_requests').doc(requestId).delete();

                      // Notify the parent widget to refresh Requests tab.
                      widget.parentRefresh();
                    },
                    child: Text('Reject'),
                    style: TextButton.styleFrom(
                      primary: Colors.white, // Text color
                      backgroundColor: Colors.red, // Background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

        },
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (widget.friendRequests == null || widget.friendRequests.isEmpty) {
      return Center(child: Text('No friend requests available.'));
    }

    return ListView.builder(
      itemCount: widget.friendRequests.length,
      itemBuilder: (context, index) {
        return _buildListItem(context, widget.friendRequests[index]);
      },
    );
  }
}