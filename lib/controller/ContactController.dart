import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:myapp/model/message_chat.dart';
import 'package:myapp/utils/spHelper.dart';

import '../routes/app_route.dart';

class ContactsController extends GetxController {
  FirebaseAuth? _firebaseAuth = null;

  FirebaseAuth get firebaseAuth => _firebaseAuth!;
  RxList<Contact> contact = RxList<Contact>();
  RxList<DocumentSnapshot> acceptedContacts = RxList<DocumentSnapshot>();
  RxList<Contact> timeExist = RxList<Contact>();
  RxList<Contact> timeNull = RxList<Contact>();
  RxList<String> acceptedContactNames = RxList<String>();
  ContactSortingService sortingService = ContactSortingService();
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

        var message = contactsQuery.snapshots().map((querySnap) {
          return querySnap.docs.map((docSnap) => docSnap).toList();
        });
        acceptedContacts.bindStream(message);

        print("===currentUserUid==" + currentUserUid);

        print("===contacts==" + acceptedContacts.length.toString());
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
    getContacts();
    // fetchAcceptedContacts();
    print("====init===");
    // AppSharedPrefs.getCartProductList().then((value) async {
    //   if (value != null) {
    //
    //   var jsonD = jsonDecode(await value[0]);
    //   var receiverUserEmail = jsonD[0];
    //   var receiverUserID = jsonD[1];
    //   var senderId = jsonD[2];
    //
    //   var param = {
    //     "receiverUserEmail": receiverUserEmail.toString(),
    //     "receiverUserID": receiverUserID.toString(),
    //     "senderId": senderId.toString(),
    //   };
    //   AppSharedPrefs.spClean();
    //   await Future.delayed(
    //     const Duration(milliseconds:  1),
    //   );
    //   await Get.toNamed(PageConst.chatView, parameters: param);
    //   }
    //
    //
    // });
  }
  final StreamController<List<Contact>> sortedContactsController = StreamController<List<Contact>>();

  void getContacts() {
    try {
      var query = FirebaseFirestore.instance
          .collection('accepted_c')
          .doc(firebaseAuth.currentUser!.uid)
          .collection('contacts');

      var contactsStream = query.snapshots().map((querySnap) {
        return querySnap.docs.map((docSnap) {
          return Contact.fromJson(docSnap);
        }).toList();
      });
      sortingService.sortContactsStream(contactsStream);
      contact.bindStream(sortingService.sortedContactsStream);
    } catch (e) {
      log('Error fetching and sorting contacts: $e');
    }
  }

  // void test() {
  //   timeExist.clear();
  //   timeNull.clear();
  //   for (var element in contact) {
  //     if (element.timestamp != null) {
  //       timeExist.add(element);
  //     }
  //     if (element.timestamp == null) {
  //       timeNull.add(element);
  //     }
  //   }
  //   timeExist.sort((a, b) {
  //     return b.timestamp!.toDate().compareTo(a.timestamp!.toDate());
  //   });
  //   contact.clear();
  //   contact.addAll(timeExist);
  //   contact.addAll(timeNull);
  // }

  @override
  void dispose() {
    sortingService.dispose();
    super.dispose();
  }
}

class ContactSortingService {
  final StreamController<List<Contact>> _sortedContactsController =
  StreamController<List<Contact>>();

  Stream<List<Contact>> get sortedContactsStream =>
      _sortedContactsController.stream;

  void sortContactsStream(Stream<List<Contact>> originalStream) {
    originalStream.listen((List<Contact> contacts) {
      contacts.sort((a, b) {
        if (a.timestamp == null && b.timestamp == null) {
          return 0; // Both are null, consider them equal
        } else if (a.timestamp == null) {
          return 1; // Null values come after non-null values
        } else if (b.timestamp == null) {
          return -1; // Non-null values come before null values
        } else {
          return b.timestamp!.compareTo(a.timestamp!);
        }
      });
      _sortedContactsController.add(List.from(contacts));
    });
  }

  void dispose() {
    _sortedContactsController.close();
  }
}