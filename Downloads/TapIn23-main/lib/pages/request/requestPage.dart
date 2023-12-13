import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home_page_requests.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  List<DocumentSnapshot> friendRequests = [];
  List<DocumentSnapshot> acceptedContacts = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchAcceptedContacts();
    fetchFriendRequests();

    // Update user's location when the app starts
    final user = _auth.currentUser;
    if (user != null) {
      updateUserLocation(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildRequestsTab();
  }

  Widget _buildRequestsTab() {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(40),
              topLeft: Radius.circular(40),
            ),
            border: Border.all(
              width: 3,
              color: Colors.white,
              style: BorderStyle.solid,
            ),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('friend_requests')
                .where('receiverId', isEqualTo: _auth.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final friendRequestsDocs = snapshot.data?.docs ?? [];

              if (friendRequestsDocs.isEmpty) {
                return Container(
                    child: Center(
                        child: Text(
                  'No friend requests available.'.toUpperCase(),
                  style: TextStyle(color: Color(0xff24786D)),
                )));
              } else {
                return Container(
                  color: Colors.black,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "My Requests",
                            style: GoogleFonts.openSans(
                              textStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: .5),
                            ),
                          ),
                        ),
                        Expanded(
                          child: HomePageRequests(
                            friendRequests: friendRequestsDocs,
                            isLoading: isLoading,
                            onRequestAccepted: (request) {
                              handleRequestAccepted(request);
                            },
                            parentRefresh: () {
                              // No need to manually refresh here, it will auto-update
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void handleRequestAccepted(DocumentSnapshot request) async {
    try {
      final user = _auth.currentUser;
      var contact = "";
      var otherUserImage = "";
      var otherUsername = "";
      var userImage = "";
      var username = "";
      if (user != null) {
        final currentUserUid = user.uid;
        final contactId = request['senderId'] as String;

        try {
          final contactDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(contactId)
              .get();
          if (contactDoc.exists) {
            final contactData = contactDoc.data() as Map<String, dynamic>;
            contact = (contactData['email'] as String?)!;
            otherUserImage = (contactData['proImage'] as String?)!;
            otherUsername = (contactData['username'] as String?)!;
          }
        } catch (e) {
          print('Error fetching contact email: $e');
        }
        try {
          final contactDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserUid)
              .get();
          if (contactDoc.exists) {
            final contactData = contactDoc.data() as Map<String, dynamic>;
            userImage = (contactData['proImage'] as String?)!;
            username = (contactData['username'] as String?)!;
          }
        } catch (e) {
          print('Error fetching contact email: $e');
        }

        final contactData = {
          'userId': currentUserUid,
          'contactId': contactId,
          'email': contact,
          'proImage': otherUserImage,
          'username': otherUsername,
          'isRead': true,
        };
        print("==currentUserUid" + currentUserUid);
        // Add the contact to Firestore's 'accepted_c' collection for the receiver
        await FirebaseFirestore.instance
            .collection('accepted_c')
            .doc(currentUserUid)
            .collection('contacts')
            .doc(contactId)
            .set(contactData);

        // Add the contact to Firestore's 'accepted_c' collection for the sender
        await FirebaseFirestore.instance
            .collection('accepted_c')
            .doc(contactId)
            .collection('contacts')
            .doc(currentUserUid)
            .set({
          'userId': contactId,
          'contactId': currentUserUid,
          'email': user.email,
          'proImage': userImage,
          'username': username,
          'isRead': true,
        });

        // Remove the accepted friend request from Firestore's 'friend_requests' collection
        await FirebaseFirestore.instance
            .collection('friend_requests')
            .doc(request.id)
            .delete();

        // Remove the accepted friend request from the friendRequests list
        setState(() {
          friendRequests.remove(request);
        });

        // Call fetchAcceptedContacts to update the acceptedContacts list
        await fetchAcceptedContacts();
      }
    } catch (error) {
      print("Failed to handle friend request acceptance: $error");
    }
  }

  Future<void> fetchAcceptedContacts() async {
    try {
      setState(() {
        isLoading = true;
      });
      final user = _auth.currentUser;
      if (user != null) {
        final currentUserUid = user.uid;
        final contactsQuery = await FirebaseFirestore.instance
            .collection('accepted_c')
            .doc(currentUserUid) // Change this line
            .collection('contacts') // Change this line
            .get();

        setState(() {
          acceptedContacts = contactsQuery.docs;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Failed to fetch accepted contacts: $error");
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

  Future<void> updateUserLocation(String userId) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update the user's location in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'location': GeoPoint(position.latitude, position.longitude),
      });

      // Check for nearby users and generate chats
      checkForNearbyUsersAndGenerateChats(position);
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  void checkForNearbyUsersAndGenerateChats(Position position) async {
    if (position != null) {
      // Define the radius within which users are considered nearby (in meters)
      double radius = 20.0;

      // Query Firestore to find nearby users
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        try {
          // Get the data as a Map
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // Check if the 'location' field exists and is not null
          if (userData.containsKey('location')) {
            GeoPoint? userLocation = userData['location'] as GeoPoint?;
            if (userLocation != null) {
              double distance = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                userLocation.latitude,
                userLocation.longitude,
              );

              // If the user is within the defined radius, create a chat
              if (distance <= radius) {
                String otherUserId = userDoc.id;
                String currentUserId = _auth.currentUser!.uid;
                String chatId = currentUserId.compareTo(otherUserId) < 0
                    ? '$currentUserId-$otherUserId'
                    : '$otherUserId-$currentUserId';

                // Check if a chat with this ID already exists
                DocumentSnapshot chatSnapshot =
                    await _firestore.collection('chats').doc(chatId).get();
                if (!chatSnapshot.exists) {
                  // Create a new chat
                  await _firestore.collection('chats').doc(chatId).set({
                    'members': [currentUserId, otherUserId],
                  });
                }
              }
            }
          } else {
            print("User document does not have a 'location' field.");
          }
        } catch (e) {
          print("Error checking user document: $e");
        }
      }
    }
  }
}