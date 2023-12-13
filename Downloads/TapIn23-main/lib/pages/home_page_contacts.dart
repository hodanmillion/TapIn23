import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/auth/auth_service.dart';
import 'package:provider/provider.dart';

class HomePageContacts extends StatefulWidget {
  final List<DocumentSnapshot> acceptedContacts;
  final bool isLoading;

  const HomePageContacts({
    Key? key,
    required this.acceptedContacts,
    required this.isLoading,
  }) : super(key: key);

  @override
  _HomePageContactsState createState() => _HomePageContactsState();
}

class _HomePageContactsState extends State<HomePageContacts> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> acceptedContactNames = [];

  @override
  void initState() {
    super.initState();
    fetchAcceptedContacts();
  }

  Future<void> fetchAcceptedContacts() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final currentUserUid = user.uid;
        final contactsQuery = await FirebaseFirestore.instance
            .collection('accepted_c')
            .where('userId', isEqualTo: currentUserUid)
            .get();

        final contactDocs = contactsQuery.docs;

        setState(() {
          widget.acceptedContacts.clear(); // Clear the existing list.
          widget.acceptedContacts.addAll(contactDocs);

          // Extract contact names and store them in acceptedContactNames.
          acceptedContactNames = contactDocs.map<String>((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['contactName'].toString(); // Explicitly cast to String.
          }).toList();
        });
      } else {
        // Handle the case where the user is not logged in
        print("User is not logged in.");
      }
    } catch (error) {
      // Handle any other errors that might occur during data retrieval
      print("Failed to fetch accepted contacts: $error");
    }
  }

  void acceptFriendRequest(String currentSenderId, String receiverId) async {
    try {
      final requestQuery = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('senderId', isEqualTo: currentSenderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      final requestDocs = requestQuery.docs;

      if (requestDocs.isNotEmpty) {
        final contactName = requestDocs[0].data()['contactName'] as String?;

        if (contactName != null) {
          // Update the request status to 'accepted'
          await requestDocs[0].reference.update({'status': 'accepted'});

          // Add the contact to the accepted contacts collection for the receiver
          await FirebaseFirestore.instance.collection('accepted_c').add({
            'userId': receiverId,
            'contactId': currentSenderId,
            'contactName': contactName,
          });

          // Add the contact to the accepted contacts collection for the sender
          await FirebaseFirestore.instance.collection('accepted_c').add({
            'userId': currentSenderId,
            'contactId': receiverId,
            'contactName': contactName,
          });

          // Remove the request from the friend_requests collection
          await requestDocs[0].reference.delete();

          // Refresh the accepted contacts list
          fetchAcceptedContacts();
        } else {
          print("contactName is null or empty.");
        }
      }
    } catch (error) {
      print("Failed to accept friend request: $error");
    }
  }

  void rejectFriendRequest(String currentSenderId, String receiverId) async {
    try {
      final requestQuery = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('senderId', isEqualTo: currentSenderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      final requestDocs = requestQuery.docs;

      if (requestDocs.isNotEmpty) {
        // Delete the friend request
        await requestDocs[0].reference.delete();

        // Refresh the accepted contacts list
        fetchAcceptedContacts();
      }
    } catch (error) {
      print("Failed to reject friend request: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Private Contacts',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [],
      ),
      body: ListView.builder(
        itemCount: acceptedContactNames.length,
        itemBuilder: (context, index) {
          final contactName = acceptedContactNames[index];

          return Card(
            elevation: 3,
            child: ListTile(
              title: Text('Contact Name: $contactName'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      // Logic to remove the accepted contact
                      final contactDoc = widget.acceptedContacts[index];
                      await FirebaseFirestore.instance.collection('accepted_c').doc(contactDoc.id).delete();
                      fetchAcceptedContacts();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      acceptFriendRequest(contactName, _auth.currentUser!.uid);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: const Color.fromARGB(255, 128, 86, 84)),
                    onPressed: () {
                      rejectFriendRequest(contactName, _auth.currentUser!.uid);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}