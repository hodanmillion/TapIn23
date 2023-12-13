import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/pages/contacts_page.dart';
import 'package:myapp/pages/home_page_requests.dart';
import 'package:myapp/pages/past_chats_page.dart';
import 'package:myapp/services/auth/auth_service.dart';
import 'package:provider/provider.dart';
import 'AddContactScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class YourRealtimeDatabaseService {
  // Add methods for subscribing to Realtime Database data, unsubscribing, and clearing data
  // For example:
  DatabaseReference? databaseReference;

  void subscribeToRealtimeDatabaseData() {
    // Subscribe to Realtime Database data, and store the reference for later use.
  }

  void unsubscribeFromRealtimeDatabaseData() {
    // Unsubscribe from Realtime Database data.
    databaseReference?.onDisconnect().cancel();
  }

  void clearRealtimeDatabaseData() {
    // Clear cached Realtime Database data or local state.
    // This could include resetting variables, clearing lists, etc.
  }
}

class YourFirestoreService {
  // Add methods for subscribing to Firestore data, unsubscribing, and clearing data
  // For example:
  StreamSubscription<DocumentSnapshot>? dataSubscription;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Define _auth here

  void subscribeToFirestoreData() {
    // Subscribe to Firestore data, and store the subscription for later use.
  }

  void unsubscribeFromFirestoreData() {
    // Unsubscribe from Firestore data.
    dataSubscription?.cancel();
  }

  void clearFirestoreData() {
    // Add the code to clear cached Firestore data or local state.
    // This could include resetting variables, clearing lists, etc.
    // For example:
    dataSubscription?.cancel();
    // Add more cleanup code as needed.
  }

  // Other cleanup tasks (e.g., unsubscribing) can be added here.
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot>? dataSubscription;

  String searchQuery = '';
  List<DocumentSnapshot> acceptedContacts = [];
  List<DocumentSnapshot> friendRequests = [];
  bool isLoading = false;
  Position? userLocation;
  late TabController _tabController;

  void clearFirebaseData() {
    // Add the code to clear cached Firestore data or local state.
    // This could include resetting variables, clearing lists, etc.
    // For example:
    dataSubscription?.cancel();
    // Add more cleanup code as needed.
  }

  void signOut() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (_auth.currentUser != null) {
      try {
        clearFirebaseData(); // Call the function to clear user data
        await authService.signOut(); // Sign out the user
      } catch (error) {
        print("Failed to sign out: $error");
      }
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

  void handleRequestAccepted(DocumentSnapshot request) async {
    try {
      final user = _auth.currentUser;
      var contact = "";
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
          }
        } catch (e) {
          print('Error fetching contact email: $e');
        }

        final contactData = {
          'userId': currentUserUid,
          'contactId': contactId,
          'email': contact
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

  void onFriendRequestSent() {
    // Implement the logic to handle the friend request sent.
    // You can update the UI or perform any necessary actions here.
    // For example, you can refresh the friend requests tab.
    fetchFriendRequests();
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

  Future<String?> getEmailForContactId(String contactId) async {
    try {
      final contactDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(contactId)
          .get();
      if (contactDoc.exists) {
        final contactData = contactDoc.data() as Map<String, dynamic>;
        return contactData['email'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching contact email: $e');
      return null;
    }
  }

  Widget _profileIcon() {
    String? userEmail = _auth.currentUser?.email ?? "Unknown User";
    String userInitial = userEmail.isNotEmpty ? userEmail[0] : "?";

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Profile"),
              content: Text("Email: $userEmail"),
              actions: [
                TextButton(
                  child: Text("Close"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Tooltip(
        message: userEmail,
        child: CircleAvatar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          radius: 30,
          child: Text(
            userInitial.toUpperCase(),
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
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

  // Function to delete a contact
  void _deleteContact(String contactId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final currentUserUid = user.uid;

        // Remove the contact from Firestore's 'accepted_c' collection for the receiver
        await FirebaseFirestore.instance
            .collection('accepted_c')
            .doc(currentUserUid)
            .collection('contacts')
            .doc(contactId)
            .delete();

        // Remove the contact from Firestore's 'accepted_c' collection for the sender
        await FirebaseFirestore.instance
            .collection('accepted_c')
            .doc(contactId)
            .collection('contacts')
            .doc(currentUserUid)
            .delete();

        // Remove the contact from the acceptedContacts list
        setState(() {
          acceptedContacts
              .removeWhere((contact) => contact['contactId'] == contactId);
        });
      }
    } catch (error) {
      print("Failed to delete contact: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    fetchAcceptedContacts();
    fetchFriendRequests();

    // Update user's location when the app starts
    final user = _auth.currentUser;
    if (user != null) {
      updateUserLocation(user.uid);
    }
  }

  void _handleTabChange() {
    // Handle tab changes here if needed
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blueAccent,
      leading: Container(width: 2, height: 2),
      title: Text(
        'TapIn',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: navigateToAddContact,
          icon: Icon(Icons.person_add, color: Colors.white),
          tooltip: "Add Contact",
        ),
        SizedBox(width: 16),
        _profileIcon(),
        SizedBox(width: 16),
        IconButton(
          onPressed: signOut,
          icon: Icon(Icons.logout, color: Colors.white),
        ),
      ],
      bottom: TabBar(
        controller: _tabController, // Use the TabController here
        indicatorColor: Colors.white,
        tabs: [
          Tab(text: 'Contacts'),
          Tab(text: 'Requests'),
          Tab(text: 'Chats'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController, // Use the TabController here
      children: [
        _buildContactsTab(),
        _buildRequestsTab(),
        _buildChatsTab(),
      ],
    );
  }

  Widget _buildContactsTab() {
    return ContactsPage();
  }

  Widget _buildContactItem(int index) {
    final data = acceptedContacts[index].data() as Map<String, dynamic>?;
    final userId = data?['userId'] as String?;
    final contactId = data?['contactId'] as String?;

    if (userId == null || contactId == null) {
      return ListTile(title: Text(''));
    }

    return FutureBuilder<String?>(
      future: getEmailForContactId(contactId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(title: Text('Loading...'));
        }
        final contactEmail = snapshot.data ?? 'Unknown';

        return Card(
          elevation: 3,
          margin: EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              contactEmail,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Navigator.of(context).push(
                    //   MaterialPageRoute(
                    //     builder: (context) => ChatPage(
                    //       receiverUserEmail: contactEmail,
                    //       receiverUserID: contactId,
                    //       senderId: _auth.currentUser!.uid,
                    //     ),
                    //   ),
                    // );
                  },
                  child: Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Call the function to delete the contact
                    _deleteContact(contactId);
                  },
                  child: Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red, // Use red color for delete button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
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
          return const Center(child: Text('No friend requests available.'));
        } else {
          return HomePageRequests(
            friendRequests: friendRequestsDocs,
            isLoading: isLoading,
            onRequestAccepted: (request) {
              handleRequestAccepted(request);
            },
            parentRefresh: () {
              // No need to manually refresh here, it will auto-update
            },
          );
        }
      },
    );
  }

  // change here
  Widget _buildChatsTab() {
    return PastChatListPage();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider(
          create: (context) => AuthService(),
          child: HomePage(),
        ),
      ),
    ),
  );
}
