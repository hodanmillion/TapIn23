import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<DocumentSnapshot>> fetchContacts() async {
    final currentUserUid = _auth.currentUser!.uid;

    // Fetch only contacts with 'accepted' status
    final contactsQuery = _firestore.collection('contacts')
        .where('userId', isEqualTo: currentUserUid)
        .where('status', isEqualTo: 'accepted');  // Ensuring only accepted contacts are fetched

    final contactsSnapshot = await contactsQuery.get();
    return contactsSnapshot.docs;
  }

  Future<List<DocumentSnapshot>> fetchFriendRequests() async {
    final currentUserUid = _auth.currentUser!.uid;

    final friendRequestsQuery = _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: currentUserUid)
        .where('status', isEqualTo: 'pending');

    final friendRequestsSnapshot = await friendRequestsQuery.get();
    return friendRequestsSnapshot.docs;
  }

  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).delete();
  }
}