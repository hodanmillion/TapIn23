import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/controller/ContactController.dart';
import '../routes/app_route.dart';

class ContactsPage extends GetView<ContactsController> {
  final controller = Get.find<ContactsController>();
  FirebaseAuth? _firebaseAuth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final data2 = await FirebaseFirestore.instance
          .collection('accepted_c')
          .doc(_firebaseAuth!.currentUser!.uid)
          .collection("contacts")
          .doc(uid)
          .get();

      bool isRead;
      if (data2.exists) {
        isRead = data2.data()?['isRead'] ?? true;
      } else {
        isRead = true;
      }

      if (data2.exists) {
        final userData = data2.data() as Map<String, dynamic>;
        userData['isRead'] = isRead;
        print(userData);
        return userData;
      }
      return null;
    } catch (e) {
      print('Error fetching user email: $e');
      return null;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userDataStream(String uid) {
    return FirebaseFirestore.instance
        .collection('accepted_c')
        .doc(_firebaseAuth!.currentUser!.uid)
        .collection("contacts")
        .doc(uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.acceptedContacts.isEmpty
          ? Container(
              color: Colors.black,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(40),
                    topLeft: Radius.circular(40),
                  ),
                  border: Border.all(
                    width: 3,
                    color: Colors.white,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Text(
                    "No contact history is available!".toUpperCase(),
                    style: TextStyle(fontSize: 14, color: Color(0xff24786D)),
                  ),
                ),
              ),
            )
          : Container(
              color: Colors.black,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
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
                        "My Contacts",
                        style: GoogleFonts.openSans(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: controller.acceptedContacts.length,
                        itemBuilder: (context, index) {
                          return _buildContactItem(index, context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildContactItem(int index, BuildContext context) {
    final data =
        controller.acceptedContacts[index].data() as Map<String, dynamic>?;
    final userId = data?['userId'] as String?;
    final contactId = data?['contactId'] as String?;
    final isRead = data?['isRead'] as bool?;

    if (userId == null || contactId == null) {
      return Container();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDataStream(contactId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.hasData && snapshot.data!.data() != null) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final isRead = userData['isRead'] as bool?;

          return Dismissible(
            key: UniqueKey(),
            onDismissed: (direction) {
              controller.deleteContact(contactId);
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            ),
            child: Card(
              elevation: 3,
              margin: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                onTap: () async {
                  print("${contactId} sdsd");
                  await controller.updateReadMessageFromList(
                    doc: contactId,
                    isRead: true,
                  );

                  var param = {
                    "receiverUserEmail": userData['email'] as String,
                    "receiverUserID": contactId,
                    "senderId": controller.firebaseAuth.currentUser!.uid,
                  };
                  Get.toNamed(PageConst.chatView, parameters: param);
                },
                child: ListTile(
                  trailing:
                      (isRead ?? false) ? null : buildNotificationIndicator(),
                  leading: userData['proImage'] != null
                      ?
                      // ClipOval(
                      //     child: CachedNetworkImage(
                      //       placeholder: (context, url) =>
                      //           const CircularProgressIndicator(
                      //         color: Colors.white,
                      //       ),
                      //       fit: BoxFit.cover,
                      //       imageUrl: userData['proImage'],
                      //       width: 50.0,
                      //       height: 50.0,
                      //     ),
                      //   )
                      Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(25),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: FirebaseImageProvider(
                                  FirebaseUrl(userData['proImage'])),
                            ),
                          ),
                        )
                      : const CircleAvatar(
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    userData['username'],
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          // Handle the case when the document data is not available
          return Text('App Refresh needed');
        }
      },
    );
  }

  Widget buildNotificationIndicator() {
    return Container(
      width: 20.0,
      height: 20.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red,
      ),
      child: Container(),
    );
  }
}