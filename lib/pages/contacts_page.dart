import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:myapp/controller/ContactController.dart';
import '../routes/app_route.dart';
import '../utils/colors.dart';

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

  Stream<DocumentSnapshot<Map<String, dynamic>>> userChatData(String chatroomId) {
    return FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatroomId)
        .snapshots();
  }


  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.acceptedContacts.isEmpty
          ? Container(
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
                style: const TextStyle(fontSize: 14, color: Color(0xff24786D)),
              ),
            ),
          )
          : Container(
            decoration: const BoxDecoration(
              color: Colors.white,


            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    "My Contacts",
                    style: GoogleFonts.openSans(
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: .5,
                        // decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15,),
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
    );
  }

  Widget _buildContactItem(int index, BuildContext context) {
    final data =
        controller.acceptedContacts[index].data() as Map<String, dynamic>?;
    final userId = data?['userId'] as String?;
    final contactId = data?['contactId'] as String?;
    final isRead = data?['isRead'] as bool?;
    final email  = data?['email'] as String;
    final imageUrl = data?['proImage'] as String;
    final username = data?['username'] as String;
    List<String> ids = [controller.firebaseAuth.currentUser!.uid, data?["contactId"]];
    ids.sort();
    String chatRoomId = ids.join("_");
    print(chatRoomId);
    if (userId == null || contactId == null) {
      return Container();
    }

    return Dismissible(
      confirmDismiss: (direction) async {
        await Future.delayed(const Duration(milliseconds: 1),() {
          _showInfoDialog(context,contactId);
          return true;
        },) ;
        return null;

      },
      key: UniqueKey(),
      onDismissed: (direction) {
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: StreamBuilder(

        stream: userChatData(chatRoomId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(''),
            );
          } else if (snapshot.data! != null) {
            // Check if snapshot.data is not null and is of the expected type
            Map<String, dynamic>? userChatMsgData;
            RxString lastMsgDate = "".obs;


            if(snapshot.data!.data() != null){
              userChatMsgData =  snapshot.data!.data() as Map<String, dynamic>;
              // profileImage.value = userData['proImage'] ?? '';

              print(userChatMsgData);

              if(userChatMsgData["time"] != null) {
                final DateTime dateTime = userChatMsgData["time"].toDate();
                final String formattedTime = DateFormat.jm().format(dateTime);
                lastMsgDate.value = formattedTime;
                print(formattedTime);

              }
            }

            print(userChatMsgData);
            print(lastMsgDate);

            // Now you can safely access userData properties
            return   Card(
              color: index.isOdd ? Colors.white  :  Colors.grey.shade50,
              elevation: 0,
              margin: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              child: InkWell(
                onTap: () async {
                  print("${contactId} sdsd");
                  await controller.updateReadMessageFromList(
                    doc: contactId,
                    isRead: true,
                  );

                  var param = {
                    "receiverUserEmail": email,
                    "receiverUserID": contactId,
                    "senderId": controller.firebaseAuth.currentUser!.uid,

                  };
                  Get.toNamed(PageConst.chatView, parameters: param);
                },
                child: ListTile(
                  trailing:  /*(isRead ?? false) ? Text(userChatMsgData == null ? "" : userChatMsgData["time"] != null ? lastMsgDate.value : "",style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),) : */Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ///
                        // buildNotificationIndicator(isRead),
                      Container(
                      width: 20.0,
                      height: 20.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isRead ?? false) ? Colors.white  : Colors.red,
                      ),
                      child: Container(),
                    ),
                        ///
                        const SizedBox(height: 8,),
                        Text(userChatMsgData == null ? "" : userChatMsgData["time"] != null ? lastMsgDate.value : "",style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),)
                      ],
                    ),
                  ),

                  /*      StreamBuilder(

                          stream: userChatData(chatRoomId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: SizedBox(),
                              );
                            } else if (snapshot.hasError) {
                              return const Center(
                                child: Text(''),
                              );
                            } else if (snapshot.data! != null) {
                              // Check if snapshot.data is not null and is of the expected type
                              Map<String, dynamic>? userChatMsgData;
                              RxString lastMsgDate = "".obs;


                              if(snapshot.data!.data() != null){
                                userChatMsgData =  snapshot.data!.data() as Map<String, dynamic>;
                                // profileImage.value = userData['proImage'] ?? '';

                                print(userChatMsgData);

                                if(userChatMsgData["time"] != null) {
                                  final DateTime dateTime = userChatMsgData["time"].toDate();
                                  final String formattedTime = DateFormat.jm().format(dateTime);
                                  lastMsgDate.value = formattedTime;
                                  print(formattedTime);

                                }
                              }

                              print(userChatMsgData);
                              print(lastMsgDate);

                              // Now you can safely access userData properties
                              return   (isRead ?? false) ? Text(userChatMsgData == null ? "" : userChatMsgData!["time"] != null ? lastMsgDate.value : "",style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey,
                              ),) : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    buildNotificationIndicator(),
                                    const SizedBox(height: 8,),
                                    Text(userChatMsgData == null ? "" : userChatMsgData!["time"] != null ? lastMsgDate.value : "",style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey,
                                    ),)
                                  ],
                                ),
                              );
                            } else {
                              // Handle the case when snapshot.data is null or of unexpected type
                              return const SizedBox();
                            }
                          },
                        ),*/


                  leading: imageUrl != ""
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal:  5.0),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25),color: AppColors.imageBorder),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(25),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: FirebaseImageProvider(
                                  FirebaseUrl(imageUrl)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                      : Padding(
                    padding: const EdgeInsets.symmetric(horizontal:  5.0),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25),color: AppColors.imageBorder),
                      child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          )
                      ),
                    ),
                  ),
                  contentPadding:
                  EdgeInsets.zero,
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username != "" ? username : username.toString().split("@")[0],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8,),
                      Text(
                        userChatMsgData == null ? "" : userChatMsgData["lastMsg"] != null ? userChatMsgData["lastMsg"] : "",
                        style: const TextStyle(
                          overflow: TextOverflow.ellipsis,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      )
                      /*StreamBuilder(

                        stream: userChatData(chatRoomId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: SizedBox(),
                            );
                          } else if (snapshot.hasError) {
                            return const Center(
                              child: Text(''),
                            );
                          } else if (snapshot.data! != null) {
                            // Check if snapshot.data is not null and is of the expected type
                            Map<String, dynamic>? userChatMsgData;
                            RxString lastMsgDate = "".obs;


                            if(snapshot.data!.data() != null){
                              userChatMsgData =  snapshot.data!.data() as Map<String, dynamic>;
                              // profileImage.value = userData['proImage'] ?? '';

                              print(userChatMsgData);

                              if(userChatMsgData["time"] != null) {
                                final DateTime dateTime = userChatMsgData["time"].toDate();
                                final String formattedTime = DateFormat.jm().format(dateTime);
                                lastMsgDate.value = formattedTime;
                                print(formattedTime);

                              }
                            }

                            print(userChatMsgData);
                            print(lastMsgDate);

                            // Now you can safely access userData properties
                            return   Text(
                        userChatMsgData == null ? "" : userChatMsgData["lastMsg"] != null ? userChatMsgData["lastMsg"] : "",
                        style: const TextStyle(
                          overflow: TextOverflow.ellipsis,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      );
                          } else {
                            // Handle the case when snapshot.data is null or of unexpected type
                            return const SizedBox();
                          }
                        },
                      ),*/

                    ],
                  ),

                ),
              ),
            );
          } else {
            // Handle the case when snapshot.data is null or of unexpected type
            return const SizedBox();
          }
        },
      ),
    );
  }

  Widget buildNotificationIndicator(isRead) {
    return Container(
      width: 20.0,
      height: 20.0,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red,
      ),
      child: Container(),
    );
  }

  void _showInfoDialog(BuildContext context,String contactId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Delete Contact",
            style: GoogleFonts.openSans(
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                  letterSpacing: .5),
            ),
          ),
          content: Text(
            "Are you sure you want to delete this contact?",
            style: GoogleFonts.openSans(
              textStyle:
              const TextStyle(color: AppColors.primaryColor, letterSpacing: .5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "NO",
                style: GoogleFonts.openSans(
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                      letterSpacing: .5),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                controller.deleteContact(contactId);
                Navigator.of(context).pop();

              },
              child: Text(
                "YES",
                style: GoogleFonts.openSans(
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                      letterSpacing: .5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}