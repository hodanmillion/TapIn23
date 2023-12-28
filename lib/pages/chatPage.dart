
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/controller/PrivateChatController.dart';
import 'package:intl/intl.dart';
import 'package:myapp/pages/auto_generated_chat_page.dart';
import 'package:myapp/services/firestore/firestore.dart';
import 'package:myapp/services/notification/notification.dart';
import 'package:myapp/services/storage/fire_storage.dart';
import 'package:myapp/utils/image_select.dart';
import 'package:myapp/utils/upload_image_dialogue.dart';
import '../model/message_chat.dart';
import '../routes/app_route.dart';
import '../utils/colors.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ignore: depend_on_referenced_packages
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends GetView<PrivateChatController> {
  final controller = Get.find<PrivateChatController>();
  int id = DateTime.now().millisecondsSinceEpoch;
  bool isChatOpen = true;

  final ScrollController _scrollController = ScrollController();
  final RxString maximizedImageUrl = ''.obs;
  final RxString profileImage = ''.obs;
  final _firestoreInstance = FirebaseFirestore.instance;

  ChatPage() {
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        if (_scrollController.position.pixels == 0) {
          // Reached the top
        } else {
          // Reached the bottom, load more messages if needed
        }
      }
    });
  }

  Widget _buildTypingIndicator() {
    return Obx(
      () {
        // Your logic for displaying the typing indicator
        if (controller.isTyping.value) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${controller.receiverUsername.value} is typing...',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          );
        } else {
          return Container(); // Or you can return null
        }
      },
    );
  }
  void _unfocusTextField(BuildContext context) {
  // Unfocus the text field
  FocusScope.of(context).unfocus();
}


  Future<void> attemptSendMessage(String receiverUserID) async {
    if (controller.messageController.value.text.isNotEmpty ||
        controller.selectedGifUrl.value.isNotEmpty) {
      await controller.sendMessage(
          receiverUserID, controller.messageController.value.text);

      controller.selectedGifUrl.value = '';
      controller.messageController.value.clear();
    }
  }

 void maximizeImage(String imageUrl) {
  maximizedImageUrl.value = imageUrl;
  // Unfocus the text field when the image is maximized
  controller.messageController.value.clear();
}


  void closeMaximizedImage() {
    maximizedImageUrl.value = '';
  }

  void deleteSelectedImage() {
    controller.selectedGifUrl.value = '';
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }



 @override
Widget build(BuildContext context) {
  return Scaffold(

    appBar: AppBar(

      centerTitle: true,
      elevation: 1,
      iconTheme: const IconThemeData(color: AppColors.primaryColor),
      title: Obx(() {
        KeyboardVisibilityBuilder(builder: (context, visible) {
          List<String> ids = [controller.firebaseAuth!.currentUser!.uid, controller.receiverUserID.value];
          ids.sort();
          String chatRoomId = ids.join("_");
          FirebaseFirestore.instance
              .collection("chat_rooms")
              .doc(chatRoomId)
              .update({
            controller.firebaseAuth!.currentUser!.uid: visible,
          });
/*        FirebaseFirestore.instance
            .collection("chat_rooms")
            .doc(chatRoomId)
            .set({'isTyping': visible});*/
          return const SizedBox();
        });
          return FutureBuilder(
            future: FirestoreDB().getUserData(controller.receiverUserID.value),
            builder: (context, snapshot) {
              List<String> ids = [controller.firebaseAuth!.currentUser!.uid, controller.receiverUserID.value];
              ids.sort();
              String chatRoomId = ids.join("_");
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(),
                );
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text('Failed to fetch data'),
                );
              } else if (snapshot.data != null &&
                  snapshot.data is Map<String, dynamic>) {
                // Check if snapshot.data is not null and is of the expected type
                Map<String, dynamic> userData =
                    snapshot.data as Map<String, dynamic>;
                profileImage.value = userData['proImage'] ?? '';

                // Now you can safely access userData properties
                return InkWell(
                  onTap: () {
                    controller.emailP.value = (userData['email'] as String?) ?? '';
                    controller.userNameP.value = userData['username'] ?? '';
                    controller.userImageP.value = userData['proImage'] ?? '';

                    Get.toNamed(PageConst.userPrivateProfilePage);
                  },
                  child: Row(
                    children: [
                      (userData['proImage'] != null)
                          ? Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.imageBorder,borderRadius: BorderRadius.circular(25)),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Container(

                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(25),
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: FirebaseImageProvider(
                                          FirebaseUrl(userData['proImage'])),
                                    ),
                                  ),
                                ),
                            ),
                          )
                          : const Icon(Icons.person_outline),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['username'] ?? userData['email'].toString().split("@")[0],
                            style: const TextStyle(color: AppColors.primaryColor,fontSize: 17,fontWeight: FontWeight.w600),
                          ),
                          StreamBuilder(

                            stream: controller.userDataStream(chatRoomId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: SizedBox(),
                                );
                              } else if (snapshot.hasError) {
                                return const Center(
                                  child: Text(''),
                                );
                              } else if (snapshot.data!.data() != null) {
                                // Check if snapshot.data is not null and is of the expected type
                                Map<String, dynamic> userData =

                                snapshot.data!.data() as Map<String, dynamic>;
                                profileImage.value = userData['proImage'] ?? '';

                                // Now you can safely access userData properties
                                return Obx(
                                      () {
                                    // Your logic for displaying the typing indicator
                                    if (userData[controller.receiverUserID.value] ?? false) {
                                      return const Text(
                                        'typing...',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14
                                        ),
                                      );
                                    } else {
                                      return Container(); // Or you can return null
                                    }
                                  },
                                );
                              } else {
                                // Handle the case when snapshot.data is null or of unexpected type
                                return const SizedBox();
                              }
                            },
                          )
                        ],
                      ),
                    ],
                  ),
                );
              } else {
                // Handle the case when snapshot.data is null or of unexpected type
                return const Center(
                  child: Text('Account Deleted'),
                );
              }
            },
          );
        }
      ),
      backgroundColor: Colors.white,
    ),
    body: SafeArea(
      child: Column(

        children: [

            Expanded(
            child: _buildMessageList(),
          ),
          StreamBuilder(

            stream: userDataStream(controller.receiverUserID.value),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(),
                );
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text(''),
                );
              } else if (snapshot.data!.data() != null) {
                Map<String, dynamic>? userChatMsgData;
                userChatMsgData =  snapshot.data!.data() as Map<String, dynamic>;
                print(userChatMsgData);
                // Now you can safely access userData properties
                return userChatMsgData["UserDeleted"] ? const SizedBox() :
                _buildTextComposer(
                  textController: controller.messageController.value,
                  context: context,
                );
              } else {
                // Handle the case when snapshot.data is null or of unexpected type
                return const SizedBox();
              }
            },
          ),

          Obx(() {
            if (maximizedImageUrl.value.isEmpty) {
              return Container();
            } else {
              return MaximizedImage(
                imageUrl: maximizedImageUrl.value,
                onClose: () {
                  closeMaximizedImage();
                },
                onImageTap: () {
                  // Unfocus the text field when the image is tapped
                  _unfocusTextField(context);
                },
              );
            }
          }),
        ],
      ),
    ),
  );
}

  Widget _buildMessageList() {
    return Obx(() {

      final reversedMessagesId = controller.messagesId.reversed.toList();
      final reversedMessages = controller.messages.reversed.toList();
      return ListView.builder(
        reverse: true,
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: reversedMessages.length,
        itemBuilder: (context, index) {
          return _buildMessageItem(reversedMessages[index],reversedMessagesId[index].isEmpty ? "" : reversedMessagesId[index] ,context);
        },
      );
    });
  }

  Widget _buildMessageItem(Message document,String id, BuildContext context) {
  final String currentUserUid = controller.firebaseAuth!.currentUser!.uid;
  bool isUrl = document.message.contains(RegExp(r'http(s)?://'));
  List<String> ids = [controller.firebaseAuth!.currentUser!.uid, controller.receiverUserID.value];
  ids.sort();
  String chatRoomId = ids.join("_");

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  var alignment = (document.senderId == currentUserUid)
      ? CrossAxisAlignment.end
      : CrossAxisAlignment.start;

  final Timestamp timestamp = document.timestamp;
  final DateTime dateTime = timestamp.toDate();
  final String formattedTime = DateFormat.jm().format(dateTime);

  List<String> sentences = [document.message];

  return Column(
    crossAxisAlignment: alignment,
    children: [
      KeyboardVisibilityBuilder(builder: (context, visible) {
        List<String> ids = [controller.firebaseAuth!.currentUser!.uid, controller.receiverUserID.value];
        ids.sort();
        String chatRoomId = ids.join("_");
        FirebaseFirestore.instance
            .collection("chat_rooms")
            .doc(chatRoomId)
            .update({
          controller.firebaseAuth!.currentUser!.uid: visible,
        });
/*        FirebaseFirestore.instance
            .collection("chat_rooms")
            .doc(chatRoomId)
            .set({'isTyping': visible});*/
        return const SizedBox();
      }),
      for (var sentence in sentences)
        GestureDetector(

          onTap: () {
            if (isUrl) {
              _launchURL(document.message);
            } else if (document.isGif) {
              maximizeImage(document.gifUrl);
            }
          },
          child: Container(

            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
            child: Column(

              crossAxisAlignment: alignment,
              children: [
                document.senderId == currentUserUid ?

                Dismissible(
                  confirmDismiss: (direction) async {
                    await Future.delayed(Duration(milliseconds: 1),() {
                      _showInfoDialog(context,chatRoomId,id);
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
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      color: (document.senderId == currentUserUid)
                          ? AppColors.chatColor
                          : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          offset: document.senderId == currentUserUid ? const Offset(0, 2) : const Offset(0, 0),
                          blurRadius: document.senderId == currentUserUid ? 6 : 0,
                        ),
                      ],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(5),
                        bottomRight: const Radius.circular(5),
                        bottomLeft: (document.senderId == currentUserUid)
                            ? const Radius.circular(5)
                            : const Radius.circular(5),
                        topRight: (document.senderId == currentUserUid)
                            ? const Radius.circular(5)
                            : const Radius.circular(5),
                      ),
                    ),
                    child: document.senderId == currentUserUid ? Column(
                      crossAxisAlignment: (document.senderId == currentUserUid)
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (document.isGif)
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) {
                                  return ImageScreen(imageUrl: document.gifUrl);
                                },
                              ));
                            },
                            child: Image.network(
                              document.gifUrl,
                              width: 150,
                            ),
                          ),
                        SelectableText(
                          sentence.trim(),
                          style: TextStyle(
                              color: (document.senderId == currentUserUid)
                                  ? Colors.black
                                  : Colors.black),
                        ),

                      ],
                    ) : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                    FutureBuilder(
                          future: FirestoreDB().getUserData(document.senderId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting ||
                                !snapshot.hasData) {
                              return const SizedBox();
                            } else if (snapshot.hasError) {
                              return const Text('');
                            }

                            profileImage.value = snapshot.data?['proImage'] ?? '';

                            final username = snapshot.data?['username'];
                            return document.senderId == currentUserUid ? const SizedBox() :
                                 GestureDetector(
                                   onTap: () {
                                     controller.emailP.value = (snapshot.data!['email'] as String?) ?? '';
                                     controller.userNameP.value = snapshot.data!['username'] ?? '';
                                     controller.userImageP.value = snapshot.data!['proImage'] ?? '';

                                     Get.toNamed(PageConst.userPrivateProfilePage);
                                   },
                                   child: Container(
                                     width: 40,
                                     height: 40,
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
                                            FirebaseUrl(snapshot.data?['proImage'])),
                                ),
                              ),
                            ),
                                     ),
                                   ),
                                 );
                          },
                        ),
                        const SizedBox(width: 10,),
                        Column(
                          crossAxisAlignment: (document.senderId == currentUserUid)
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            FutureBuilder(
                              future: FirestoreDB().getUserData(document.senderId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting ||
                                    !snapshot.hasData) {
                                  return const Text('Loading...');
                                } else if (snapshot.hasError) {
                                  return const Text('User');
                                }

                                profileImage.value = snapshot.data?['proImage'] ?? '';

                                final username = snapshot.data?['username'] != null && snapshot.data!['username'] != "" ? snapshot.data!['username']  : snapshot.data!['email'].toString().split("@")[0] ;
                                return document.senderId == currentUserUid ? const SizedBox() : Text(
                                  (document.senderId == currentUserUid)
                                      ? 'You'
                                      : username ?? 'Unknown User',
                                  style: TextStyle(
                                    color: (document.senderId == currentUserUid)
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ) ;
                              },
                            ),
                            if (document.isGif)
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) {
                                      return ImageScreen(imageUrl: document.gifUrl);
                                    },
                                  ));
                                },
                                child: Image.network(
                                  document.gifUrl,
                                  width: 150,
                                ),
                              ),
                            const SizedBox(height: 5,),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5.0),
                              child: SizedBox(
                                // color: Colors.yellow,
                                width: MediaQuery.of(context).size.width /1.8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SelectableText(
                                      sentence.trim(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                          color: (document.senderId == currentUserUid)
                                              ? Colors.white
                                              : Colors.black,overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(height: 10,),
                                    Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                              onTap: () async {
                                                List<String> ids = [controller.firebaseAuth!.currentUser!.uid, controller.receiverUserID.value];
                                                ids.sort();
                                                String chatRoomId = ids.join("_");
                                                document.like == "1" ?
                                                await FirebaseFirestore.instance
                                                    .collection('chat_rooms')
                                                    .doc(chatRoomId)
                                                    .collection('messages').doc(id)
                                                    .update({"like" : "0"}) :

                                                await FirebaseFirestore.instance
                                                    .collection('chat_rooms')
                                                    .doc(chatRoomId)
                                                    .collection('messages').doc(id)
                                                    .update({"like" : "1"});
                                              },
                                              child: document.like == "1" ? const Icon(Icons.favorite,color: Colors.red,) : const Icon(Icons.favorite_border_rounded,))
                                          /*PopupMenuButton(
                                            shadowColor: Colors.transparent,
                                            padding: EdgeInsets.zero,
                                            color: Colors.transparent,
                                            child: const Center(child: Icon(Icons.favorite_border_rounded,)),
                                            itemBuilder: (context) {
                                              return List.generate(1, (index) {
                                                List<String> ids = [controller.firebaseAuth!.currentUser!.uid, controller.receiverUserID.value];
                                                ids.sort();
                                                String chatRoomId = ids.join("_");
                                                return PopupMenuItem(
                                                  height: 20,
                                                  // padding: EdgeInsets.only(top: 10, right: 15),
                                                  value: index,
                                                  child: Container(

                                                    decoration: const BoxDecoration(
                                                        borderRadius: BorderRadius.only(
                                                            bottomLeft: Radius.circular(12),
                                                            topRight: Radius.circular(12),
                                                            bottomRight: Radius.circular(12),
                                                            topLeft: Radius.circular(12)),
                                                        color: Colors.grey),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Padding(
                                                              padding: const EdgeInsets.all(2.0),
                                                              child: GestureDetector(onTap: () async {
                                                                await FirebaseFirestore.instance
                                                                    .collection('chat_rooms')
                                                                    .doc(chatRoomId)
                                                                    .collection('messages').doc(id)
                                                                    .update({"lick" : 1});
                                                                Navigator.pop(context);
                                                              },child: Image.asset("images/imoj.png",width: 35,)),
                                                            ),
                                                            Padding(
                                                              padding: const EdgeInsets.all(2.0),
                                                              child: GestureDetector(onTap: () async {

                                                                await FirebaseFirestore.instance
                                                                    .collection('chat_rooms')
                                                                    .doc(chatRoomId)
                                                                    .collection('messages').doc(id)
                                                                    .update({"lick" : 2});
                                                                Navigator.pop(context);

                                                              },child: Image.asset("images/imojji2.png",width: 35,)),
                                                            ),
                                                            Padding(
                                                              padding: const EdgeInsets.all(2.0),
                                                              child: GestureDetector(onTap: () async {

                                                                await FirebaseFirestore.instance
                                                                    .collection('chat_rooms')
                                                                    .doc(chatRoomId)
                                                                    .collection('messages').doc(id)
                                                                    .update({"lick" : 3});
                                                                Navigator.pop(context);

                                                              },child: Image.asset("images/imojji3.png",width: 35,)),
                                                            ),
                                                            Padding(
                                                              padding: const EdgeInsets.all(2.0),
                                                              child: GestureDetector(onTap: () async {

                                                                await FirebaseFirestore.instance
                                                                    .collection('chat_rooms')
                                                                    .doc(chatRoomId)
                                                                    .collection('messages').doc(id)
                                                                    .update({"lick" : 4});
                                                                Navigator.pop(context);

                                                              },child: Image.asset("images/imojji4.png",width: 35,)),
                                                            ),
                                                            Padding(
                                                              padding: const EdgeInsets.all(2.0),
                                                              child: GestureDetector(onTap: () async {
                                                                await FirebaseFirestore.instance
                                                                    .collection('chat_rooms')
                                                                    .doc(chatRoomId)
                                                                    .collection('messages').doc(id)
                                                                    .update({"lick" : 5});
                                                                Navigator.pop(context);

                                                              },child: Image.asset("images/imojji5.png",width: 35,)),
                                                            ),
                                                          ]),
                                                    ),
                                                  ),
                                                );
                                              });
                                            },
                                          )*/,
                                          Text(
                                            formattedTime,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.black45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          ],
                        ),
                      ],
                    ),
                  ),
                ) : Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    color: (document.senderId == currentUserUid)
                        ? AppColors.chatColor
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        offset: document.senderId == currentUserUid ? const Offset(0, 2) : const Offset(0, 0),
                        blurRadius: document.senderId == currentUserUid ? 6 : 0,
                      ),
                    ],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(5),
                      bottomRight: const Radius.circular(5),
                      bottomLeft: (document.senderId == currentUserUid)
                          ? const Radius.circular(5)
                          : const Radius.circular(5),
                      topRight: (document.senderId == currentUserUid)
                          ? const Radius.circular(5)
                          : const Radius.circular(5),
                    ),
                  ),
                  child: document.senderId == currentUserUid ? Column(
                    crossAxisAlignment: (document.senderId == currentUserUid)
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (document.isGif)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) {
                                return ImageScreen(imageUrl: document.gifUrl);
                              },
                            ));
                          },
                          child: Image.network(
                            document.gifUrl,
                            width: 150,
                          ),
                        ),
                      SelectableText(
                        sentence.trim(),
                        style: TextStyle(
                            color: (document.senderId == currentUserUid)
                                ? Colors.black
                                : Colors.black),
                      ),

                    ],
                  ) : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      FutureBuilder(
                        future: FirestoreDB().getUserData(document.senderId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting ||
                              !snapshot.hasData) {
                            return const SizedBox();
                          } else if (snapshot.hasError) {
                            return const Text('');
                          }

                          profileImage.value = snapshot.data?['proImage'] ?? '';

                          final username = snapshot.data?['username'] != "" && snapshot.data!['username'] != "" ? snapshot.data!['username'] : snapshot.data!['username'].toString().split("@")[0] ;
                          return document.senderId == currentUserUid ? const SizedBox() :
                          snapshot.data!['proImage'] != null && snapshot.data!['proImage'] != "" ?  GestureDetector(
                            onTap: () {
                              controller.emailP.value = (snapshot.data!['email'] as String?) ?? '';
                              controller.userNameP.value = snapshot.data!['username'] != null && snapshot.data!['username'] != "" ? snapshot.data!['username'] : snapshot.data!['email'].toString().split("@")[0] ;
                              controller.userImageP.value = snapshot.data!['proImage'] ?? '';

                              Get.toNamed(PageConst.userPrivateProfilePage);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
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
                                          FirebaseUrl(snapshot.data?['proImage'])),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ) : GestureDetector(
                            onTap: () {
                              controller.emailP.value = (snapshot.data!['email'] as String?) ?? '';
                              controller.userNameP.value = snapshot.data!['username'] != null && snapshot.data!['username'] != "" ? snapshot.data!['username'] : snapshot.data!['email'].toString().split("@")[0] ;
                              controller.userImageP.value = snapshot.data!['proImage'] ?? '';

                              Get.toNamed(PageConst.userPrivateProfilePage);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(25),color: AppColors.imageBorder),
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(Icons.person_outline),
                              ),
                            ),
                          ) ;
                        },
                      ),
                      const SizedBox(width: 10,),
                      Column(
                        crossAxisAlignment: (document.senderId == currentUserUid)
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          FutureBuilder(
                            future: FirestoreDB().getUserData(document.senderId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting ||
                                  !snapshot.hasData) {
                                return const Text('Loading...');
                              } else if (snapshot.hasError) {
                                return const Text('User');
                              }

                              profileImage.value = snapshot.data?['proImage'] ?? '';

                              final username = snapshot.data?['username'] != null && snapshot.data!['username'] != "" ? snapshot.data!['username'] : snapshot.data!['email'].toString().split("@")[0];
                              return document.senderId == currentUserUid ? const SizedBox() : Text(
                                (document.senderId == currentUserUid)
                                    ? 'You'
                                    : username ?? 'Unknown User',
                                style: TextStyle(
                                  color: (document.senderId == currentUserUid)
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ) ;
                            },
                          ),
                          if (document.isGif)
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) {
                                    return ImageScreen(imageUrl: document.gifUrl);
                                  },
                                ));
                              },
                              child: Image.network(
                                document.gifUrl,
                                width: 150,
                              ),
                            ),
                          const SizedBox(height: 5,),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5.0),
                            child: SizedBox(
                              // color: Colors.yellow,
                              width: MediaQuery.of(context).size.width /1.8,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(
                                    sentence.trim(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: (document.senderId == currentUserUid)
                                            ? Colors.white
                                            : Colors.black,overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(height: 10,),
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                            onTap: () async {
                                              List<String> ids = [controller.firebaseAuth!.currentUser!.uid, controller.receiverUserID.value];
                                              ids.sort();
                                              String chatRoomId = ids.join("_");
                                              document.like == "1" ?
                                              await FirebaseFirestore.instance
                                                  .collection('chat_rooms')
                                                  .doc(chatRoomId)
                                                  .collection('messages').doc(id)
                                                  .update({"like" : "0"}) :

                                              await FirebaseFirestore.instance
                                                  .collection('chat_rooms')
                                                  .doc(chatRoomId)
                                                  .collection('messages').doc(id)
                                                  .update({"like" : "1"});
                                            },
                                            child: document.like == "1" ? const Icon(Icons.favorite,color: Colors.red,) : const Icon(Icons.favorite_border_rounded,))
                                        /*PopupMenuButton(
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.zero,
                                          color: Colors.transparent,
                                          child: const Center(child: Icon(Icons.favorite_border_rounded,)),
                                          itemBuilder: (context) {
                                            return List.generate(1, (index) {
                                              List<String> ids = [controller.firebaseAuth!.currentUser!.uid, controller.receiverUserID.value];
                                              ids.sort();
                                              String chatRoomId = ids.join("_");
                                              return PopupMenuItem(
                                                height: 20,
                                                // padding: EdgeInsets.only(top: 10, right: 15),
                                                value: index,
                                                child: Container(

                                                  decoration: const BoxDecoration(
                                                      borderRadius: BorderRadius.only(
                                                          bottomLeft: Radius.circular(12),
                                                          topRight: Radius.circular(12),
                                                          bottomRight: Radius.circular(12),
                                                          topLeft: Radius.circular(12)),
                                                      color: Colors.grey),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Padding(
                                                            padding: const EdgeInsets.all(2.0),
                                                            child: GestureDetector(onTap: () async {
                                                              await FirebaseFirestore.instance
                                                                  .collection('chat_rooms')
                                                                  .doc(chatRoomId)
                                                                  .collection('messages').doc(id)
                                                                  .update({"lick" : 1});
                                                              Navigator.pop(context);
                                                            },child: Image.asset("images/imoj.png",width: 35,)),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.all(2.0),
                                                            child: GestureDetector(onTap: () async {

                                                              await FirebaseFirestore.instance
                                                                  .collection('chat_rooms')
                                                                  .doc(chatRoomId)
                                                                  .collection('messages').doc(id)
                                                                  .update({"lick" : 2});
                                                              Navigator.pop(context);

                                                            },child: Image.asset("images/imojji2.png",width: 35,)),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.all(2.0),
                                                            child: GestureDetector(onTap: () async {

                                                              await FirebaseFirestore.instance
                                                                  .collection('chat_rooms')
                                                                  .doc(chatRoomId)
                                                                  .collection('messages').doc(id)
                                                                  .update({"lick" : 3});
                                                              Navigator.pop(context);

                                                            },child: Image.asset("images/imojji3.png",width: 35,)),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.all(2.0),
                                                            child: GestureDetector(onTap: () async {

                                                              await FirebaseFirestore.instance
                                                                  .collection('chat_rooms')
                                                                  .doc(chatRoomId)
                                                                  .collection('messages').doc(id)
                                                                  .update({"lick" : 4});
                                                              Navigator.pop(context);

                                                            },child: Image.asset("images/imojji4.png",width: 35,)),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.all(2.0),
                                                            child: GestureDetector(onTap: () async {
                                                              await FirebaseFirestore.instance
                                                                  .collection('chat_rooms')
                                                                  .doc(chatRoomId)
                                                                  .collection('messages').doc(id)
                                                                  .update({"lick" : 5});
                                                              Navigator.pop(context);

                                                            },child: Image.asset("images/imojji5.png",width: 35,)),
                                                          ),
                                                        ]),
                                                  ),
                                                ),
                                              );
                                            });
                                          },
                                        )*/,
                                        Text(
                                          formattedTime,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.black45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        ],
                      ),
                    ],
                  ),
                ),
                if(document.senderId == currentUserUid)
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(

                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [

                      if(document.like == "1")
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical:  5.0),
                          child: Icon(Icons.favorite,color: Colors.red,size: 16,),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.black45,
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 5,)

              ],
            ),
          ),
        ),
    ],
  );
}

  PopupMenuItem _buildPopupMenuItem(String title, groupChatId, timeStamp,context) {
    return PopupMenuItem(

      child: GestureDetector(
          onTap: () async {
              await FirebaseFirestore.instance
                  .collection("chat_rooms")
                  .doc(groupChatId.toString())
                  .collection("messages")
                  .doc(timeStamp.toString())
                  .delete().whenComplete(() => Navigator.pop(context)
              );

          },
          child: Text(title)),
    );
  }

  Widget _buildTextComposer({
    required TextEditingController textController,
    required BuildContext context,
  }) {
    return Column(
      children: [
        IconTheme(
          data: const IconThemeData(color: AppColors.primaryColor),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: <Widget>[
                Obx(() => controller.selectedGifUrl.value.isEmpty
                    ? Container()
                    : Column(
                        children: [
                          Image.network(
                            controller.selectedGifUrl.value,
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              deleteSelectedImage();
                            },
                          ),
                        ],
                      )),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () {
                    showUploadOption(context, () async {
                      Uint8List? imageCode =
                          await handleImageUpload(ImageSource.gallery);
                      if (imageCode != null) {
                        try {
                          String imageUrl = await StorageMethods()
                              .uploadImageToStorage(
                                  'chatImages/${controller.getMessageRoomID(FirebaseAuth.instance.currentUser!.uid, controller.receiverUserID.string)}/${DateTime.now().millisecondsSinceEpoch}',
                                  imageCode,
                                  false);

                          print('Image uploaded: $imageUrl');
                          controller.selectedGifUrl.value = imageUrl;
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          print('Error occurred: $e');
                        }
                      }
                    }, () async {
                      Uint8List? imageCode =
                          await handleImageUpload(ImageSource.camera);
                      if (imageCode != null) {
                        try {
                          String imageUrl = await StorageMethods()
                              .uploadImageToStorage(
                                  'chatImages/${controller.getMessageRoomID(FirebaseAuth.instance.currentUser!.uid, controller.receiverUserID.string)}/${DateTime.now().millisecondsSinceEpoch}',
                                  imageCode,
                                  false);
                          print('Image uploaded: $imageUrl');
                          controller.selectedGifUrl.value = imageUrl;
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          print('Error occurred: $e');
                        }
                      }
                    }, true);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.gif),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              TextFormField(
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (term) {
                                  controller.searchByGifName();
                                },
                                controller: controller.searchGifText.value,
                                decoration: InputDecoration(
                                  labelText: 'Search Gif...',
                                  labelStyle: const TextStyle(
                                      color: AppColors.primaryColor),
                                  suffixIcon: Obx(
                                    () => controller.isSeachActive.value
                                        ? IconButton(
                                            icon: const Icon(Icons.close,
                                                color: AppColors.primaryColor),
                                            onPressed: controller.cancelSearch,
                                          )
                                        : IconButton(
                                            icon: const Icon(Icons.search,
                                                color: AppColors.primaryColor),
                                            onPressed: controller.searchByGifName,
                                          ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                        color: AppColors.primaryColor),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              Expanded(
                                child: Obx(() => GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 8.0,
                                        crossAxisSpacing: 8.0,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      itemCount: controller.gifUrl.length,
                                      itemBuilder: (context, index) {
                                        return GestureDetector(
                                          onTap: () {
                                            controller.selectedGifUrl.value =
                                                controller.gifUrl[index];
                                            Navigator.pop(context);
                                          },
                                          child: Image.network(
                                            controller.gifUrl[index],
                                          ),
                                        );
                                      },
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Flexible(
                  child: TextField(
                    controller: textController,
                    onChanged: (text) {
                      // Handle typing indicator logic here
                      if (text.isNotEmpty) {
                        // Update UI to indicate the contact is typing
                        // You can use a widget or set a variable to manage the state
                      } else {
                        // Update UI to clear typing indicator
                      }
                    },
                    onSubmitted: (value) => _handleSubmitted(textController.text),
                    maxLines: null, // Set to null for multi-line input
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Send a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    controller.isSendMessage.value ? null : _handleSubmitted(textController.text);
                  },
                ),
              ],
            ),
          ),
        ),
        _buildTypingIndicator(), // Show typing indicator
      ],
    );
  }

  Future<String> fetchSenderUsername(String senderId) async {
    final usersCollection = FirebaseFirestore.instance.collection('users');

    try {
      DocumentSnapshot senderSnapshot =
          await usersCollection.doc(senderId).get();
      if (senderSnapshot.exists) {
        String senderUsername = senderSnapshot['username'];
        return senderUsername;
      }
    } catch (e) {
      print('Failed to fetch sender username: $e');
    }

    return 'Unknown User';
  }

  void openChat() {
    isChatOpen = true;
  }

  void closeChat() {
    isChatOpen = false;
  }

void _handleSubmitted(String text) async {
  // Check if the receiver's account exists
  controller.isSendMessage.value = true;
  bool isReceiverAccountExists =
      await FirestoreDB().isUserExists(controller.receiverUserID.value);

  if (!isReceiverAccountExists) {
    // Display error message indicating that the receiver's account is deleted
    Get.snackbar(
      'Cannot Send Message',
      'The receiver\'s account has been deleted.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    controller.isSendMessage.value = false;
    return;
  }

  // Send the message only if the receiver's account exists
  await attemptSendMessage(controller.receiverUserID.value);

  // Update read message
  await controller.updateReadMessage(
    doc: controller.receiverUserID.value,
    isRead: false,
  );

  openChat();

  try {
    String token =
        await getUserToken(controller.receiverUserID.value);
    String senderId = controller.firebaseAuth!.currentUser!.uid;
    String senderUsername = await fetchSenderUsername(senderId);

    await sendNotification(

      token,
      text.isNotEmpty ? text : controller.selectedGifUrl.value,
      'Message from $senderUsername',
      {
        'receiverUserEmail': controller.receiverUserEmail.value,
        'receiverUserID': controller.firebaseAuth!.currentUser!.uid,
        'senderId': controller.receiverUserID.value,
      },
    );
    controller.isSendMessage.value = false;

    closeChat();
  } catch (e) {
    controller.isSendMessage.value = false;

    print('Error sending message: $e');
    // Handle the error appropriately (e.g., show an error message to the user)
  }
}

  Stream<DocumentSnapshot<Map<String, dynamic>>> userDataStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots();
  }

  Future<void> sendNotification(
      String token,
      String body,
      String title,
      Map<String, dynamic> data,
      ) async {
    print('sending notification');
    try {
      final res = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
          'key=AAAAk2pWUzU:APA91bFBosyFQlGHRK1aHE-D9P2xJOTHjd5bM0MRIjyOPqRsH0uqJqCS7rW4wfYN4pz_tB_JEg-FrxIiowuYCaG3V9cjaUICGkmfvTEEWy_6i9EEnVLZL6LSrjhBF-EOFLCL7tpQeNWe'
        },
        body: jsonEncode({
          'data': data,
          "to": token,
          "notification": {
            "title": title,
            "body": body,
          }
        }),
      );
      print(res.body);
      print('noti send succ');
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  Future<String> getUserToken(String uid) async {
    CollectionReference userData = _firestoreInstance.collection('users');
    DocumentSnapshot docData = await userData.doc(uid).get();
    if (docData.exists) {
      return docData['token'];
    }
    return '';
  }

  void _showInfoDialog(BuildContext context,String groupId,String contactId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Delete Message",
            style: GoogleFonts.openSans(
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                  letterSpacing: .5),
            ),
          ),
          content: Text(
            "Are you sure you want to delete this Message?",
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
              onPressed: () async {

                await FirebaseFirestore.instance
                    .collection("chat_rooms")
                    .doc(groupId.toString())
                    .collection("messages")
                    .doc(contactId.toString())
                    .delete().whenComplete(() => Navigator.pop(context)
                );
/*
                Navigator.of(context).pop();
*/

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

class MaximizedImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onClose;
  final VoidCallback onImageTap;

  MaximizedImage({
    required this.imageUrl,
    required this.onClose,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Call the onImageTap callback when the image is tapped
        onImageTap();
        onClose();
      },
      child: Container(
        color: Colors.black,
        child: Center(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
