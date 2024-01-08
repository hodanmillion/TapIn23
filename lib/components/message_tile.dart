import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/pages/auto_generated_chat_page.dart';
import 'package:myapp/utils/colors.dart';
import 'package:http/http.dart' as http;

import '../pages/publicChatProfile.dart';

class MessageTile extends StatefulWidget {
  final String message;
  final String sender;
  final bool sentByMe;
  final String? gifUrl;
  final bool? isGif;
  final String? senderid;
  final String? time;

  const MessageTile({
    Key? key,
    required this.message,
    required this.sender,
    required this.sentByMe,
    required this.gifUrl,
    required this.isGif,
     this.senderid,
    this.time,
  }) : super(key: key);

  @override
  State<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile> {
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> friendRequests = [];
  RxString username = "".obs;
  RxString userurl = "".obs;
  RxString email = "".obs;
  RxInt color = 0.obs;
  RxBool imageReady = false.obs;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    RxString emailP = ''.obs;
    RxString userNameP = ''.obs;
    RxString userImageP = ''.obs;
    RxString userId = ''.obs;
    print('Building MessageTile: ${widget.message}, sentByMe: ${widget.sentByMe}');

    return Align(
      alignment: widget.sentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: widget.sentByMe ? 8 : 2),
        padding: EdgeInsets.symmetric(horizontal: widget.sentByMe ? 12 : 2,vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: widget.sentByMe ? AppColors.chatColor : Colors.white,
          border: Border.all(color: widget.sentByMe ? Colors.transparent : Colors.grey.shade100,)
        ),
        child: Column(
          crossAxisAlignment: widget.sentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            widget.sentByMe ? const SizedBox() :  Obx(
              () {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.senderid)
                    .get()
                    .then((DocumentSnapshot documentSnapshot) {
                  if (documentSnapshot.exists) {
                    final test = documentSnapshot.data() as Map;
                    username.value  = test['username'] ?? "";
                    userurl.value  = test['proImage'] ?? "";
                    email.value  = test['email'] ?? "";
                    color.value = test['color'] ?? "";
                  }

                });
                return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          userurl.value.isNotEmpty ? GestureDetector(
                onTap: () {
                  emailP.value = widget.sender ?? '';
                  userNameP.value = username.value ?? '';
                  userImageP.value = userurl.value ?? '';
                  userId.value  = widget.senderid ?? '';
                  Get.to(PublicChatProfilePage(email: emailP.value,name: userNameP.value,image: userImageP.value,userId: userId.value,onFriendRequestSent: onFriendRequestSent));
                },

                child: ClipOval(

                  child: CachedNetworkImage(
                    placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                    fit: BoxFit.cover,
                    imageUrl: userurl.value,
                    width: 35.0,
                    height: 35.0,
                  ),
                )/*Container(
                  decoration: BoxDecoration(
                    color: AppColors.imageBorder,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  width: 35,
                  height: 35,
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Container(

                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(25),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: FirebaseImageProvider(
                              FirebaseUrl(userurl.value)),
                        ),
                      ),
                    ),
                  ),
                )*/,
          ) : Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(color: AppColors.imageBorder,borderRadius: BorderRadius.circular(25)),
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Container(

                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(Icons.person),
                  ),
                ),
          ),
          SizedBox(width: 10,),
          Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username.value.isEmpty ? widget.sender.split("@").first : username.value,
                    /*userData != null ? userData["username"] ?? 'User' : "User",*/
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(color.value),
                    ),
                  ),

                  if (widget.isGif != null && widget.isGif!) // Check if gifUrl is not null
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) {
                            return ImageScreen(imageUrl: widget.gifUrl!);
                          },
                        ));
                      },
                      child: SizedBox(
                        width: 150, // Adjust the width as needed
                        child: Image.network(
                          widget.gifUrl!,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading GIF: $error');
                            return const Text('');
                          },
                          width: 150, // Adjust the width as needed
                        ),
                      ),
                    ),
                  const SizedBox(height: 5,),
                  Text(
                    widget.message,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w400
                    ),
                  ),
                  const SizedBox(height: 10,),
                  widget.sentByMe ? const SizedBox() :  Text(
                    widget.time!,
                    style:  const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),

                ],
          ),
        ],
      );
              }
            ),
            if(widget.sentByMe)
            if (widget.isGif != null && widget.isGif!) // Check if gifUrl is not null
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) {
                      return ImageScreen(imageUrl: widget.gifUrl!);
                    },
                  ));
                },
                child: SizedBox(
                  width: 150, // Adjust the width as needed
                  child: Image.network(
                    widget.gifUrl!,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading GIF: $error');
                      return const Text('');
                    },
                    width: 150, // Adjust the width as needed
                  ),
                ),
              ),
            if(widget.sentByMe)
              const SizedBox(height: 5,),
            if(widget.sentByMe)
              Text(
              widget.message,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w400
              ),
            ),
            if(widget.sentByMe)

              const SizedBox(height: 10,),
            if(widget.sentByMe)
            Text(
              widget.time!,
              style:  const TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onFriendRequestSent() {
    fetchFriendRequests();
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
}




class RandomColorModel {
  Random random = Random();
  Color getColor() {
    return Color.fromARGB(255, random.nextInt(200),
        random.nextInt(200), random.nextInt(200));
  }
}



