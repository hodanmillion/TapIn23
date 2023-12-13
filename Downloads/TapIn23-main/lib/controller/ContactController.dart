import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ContactsController extends GetxController {
  FirebaseAuth? _firebaseAuth = null;

  FirebaseAuth get firebaseAuth => _firebaseAuth!;
  RxList<DocumentSnapshot> acceptedContacts = RxList<DocumentSnapshot>();
  RxList<String> acceptedContactNames = RxList<String>();

  RxString contactEmail = "".obs;

  void deleteContact(String contactId) async {
  try {
    final user = firebaseAuth.currentUser;
    if (user != null) {
      final currentUserUid = user.uid;

      // Remove the contact from Firestore's 'accepted_c' collection for the current user
      await FirebaseFirestore.instance
          .collection('accepted_c')
          .doc(currentUserUid)
          .collection('contacts')
          .doc(contactId)
          .delete();

      // Remove the contact from Firestore's 'accepted_c' collection for the other user
      await FirebaseFirestore.instance
          .collection('accepted_c')
          .doc(contactId)
          .collection('contacts')
          .doc(currentUserUid)
          .delete();

      // Remove the contact from the acceptedContacts list
      acceptedContacts
          .removeWhere((contact) => contact['contactId'] == contactId);

      print("Deleted contact with ID: $contactId");
    }
  } catch (error) {
    print("Failed to delete contact: $error");
  }
}

  Future<void> fetchAcceptedContacts() async {
    try {
      final user = _firebaseAuth!.currentUser;
      print('user is fetching data');
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

  Future<bool?> updateReadMessageFromList(
      {required String doc, required bool isRead}) async {
    try {
      final user = _firebaseAuth!.currentUser;
      if (user != null) {
        final currentUserUid = user.uid;

        print("currentUserUid $currentUserUid $doc");
        // Query for unread messages in the 'contacts' collection
        final unreadMessagesQuery = FirebaseFirestore.instance
            .collection('accepted_c')
            .doc(currentUserUid)
            .collection('contacts')
            .doc(doc)
            .update({"isRead": isRead});
      }
    } catch (error) {
      // Handle any other errors that might occur during data retrieval
      print("Failed to fetch accepted contacts: $error");
    }
  }

  Future<bool?> updateReadMessage(
      {required String doc, required bool isRead}) async {
    try {
      final user = _firebaseAuth!.currentUser;
      if (user != null) {
        final currentUserUid = user.uid;
        // Query for unread messages in the 'contacts' collection
        final unreadMessagesQuery = FirebaseFirestore.instance
            .collection('accepted_c')
            .doc(currentUserUid)
            .collection('contacts')
            .doc(doc)
            .update({"isRead": isRead});
      }
    } catch (error) {
      // Handle any other errors that might occur during data retrieval
      print("Failed to fetch accepted contacts: $error");
    }
  }

  @override
  void onInit() {
    super.onInit();
    _firebaseAuth = FirebaseAuth.instance;
    print("====init===");
    fetchAcceptedContacts();
  }

  @override
  void dispose() {
    // TODO: implement dispose

    super.dispose();
  }
}