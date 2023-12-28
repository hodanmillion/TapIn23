import 'dart:math';

import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/pages/auto_generated_chat_page.dart';
import 'package:myapp/routes/app_route.dart';
import 'package:myapp/services/firestore/firestore.dart';
import 'package:myapp/utils/colors.dart';

import '../pages/publicChatProfile.dart';

class MessageTile extends StatelessWidget {
  final String message;
  final String sender;
  final bool sentByMe;
  final String? gifUrl;
  final bool? isGif;
  final String? time;

  const MessageTile({
    Key? key,
    required this.message,
    required this.sender,
    required this.sentByMe,
    required this.gifUrl,
    required this.isGif, this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    RxString emailP = ''.obs;
    RxString userNameP = ''.obs;
    RxString userImageP = ''.obs;
    RxString userId = ''.obs;
    print('Building MessageTile: $message, sentByMe: $sentByMe');

    return Align(
      alignment: sentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: sentByMe ? 8 : 2),
        padding: EdgeInsets.symmetric(horizontal: sentByMe ? 12 : 2,vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: sentByMe ? AppColors.chatColor : Colors.white,
          border: Border.all(color: sentByMe ? Colors.transparent : Colors.grey.shade100,)
        ),
        child: Column(
          crossAxisAlignment: sentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: FirestoreDB().getUserDataByEmail(sender),
              builder: (context, snapshot) {
                // Handle different states
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('');
                } else if (snapshot.hasError) {
                  return const Text('');
                }

                // Use the null-aware operator to access data safely
                final userData = snapshot.data?.data();


                // Display the username
                return sentByMe ? const SizedBox() :  Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    userData != null ? userData['proImage'] != null ? GestureDetector(
                      onTap: () {
              /*          Map<String, String> params = {
                          "email": (userData['email'] as String?) ?? '',
                          "username": userData['username'] ?? '',
                          "proImage": userData['proImage'] ?? '',
                          "userId": userData['uid'] ?? ''

                        };


                        Get.toNamed(PageConst.publicChatProfilePage,arguments: params);*/
                        emailP.value = (userData['email'] as String?) ?? '';
                        userNameP.value = userData['username'] ?? '';
                        userImageP.value = userData['proImage'] ?? '';
                        userId.value  = userData['uid'] ?? '';
                        Get.to(PublicChatProfilePage(email: emailP.value,name: userNameP.value,image: userImageP.value,userId: userId.value,));
                      },
                      child: Container(
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
                                FirebaseUrl(userData['proImage'])),
                          ),
                  ),
                ),
                        ),
                      ),
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
                        Text(
                          userData != null ? userData["username"] ?? 'User' : "User",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(userData["color"]),
                          ),
                        ),

                        if (isGif != null && isGif!) // Check if gifUrl is not null
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) {
                                  return ImageScreen(imageUrl: gifUrl!);
                                },
                              ));
                            },
                            child: SizedBox(
                              width: 150, // Adjust the width as needed
                              child: Image.network(
                                gifUrl!,
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
                          message,
                          style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w400
                          ),
                        ),
                        const SizedBox(height: 10,),
                        sentByMe ? const SizedBox() :  Text(
                          time!,
                          style:  const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),

                      ],
                    ),
                  ],
                );
              },
            ),
            if(sentByMe)
            if (isGif != null && isGif!) // Check if gifUrl is not null
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) {
                      return ImageScreen(imageUrl: gifUrl!);
                    },
                  ));
                },
                child: SizedBox(
                  width: 150, // Adjust the width as needed
                  child: Image.network(
                    gifUrl!,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading GIF: $error');
                      return const Text('');
                    },
                    width: 150, // Adjust the width as needed
                  ),
                ),
              ),
            if(sentByMe)
              const SizedBox(height: 5,),
            if(sentByMe)
              Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w400
              ),
            ),
            if(sentByMe)

              const SizedBox(height: 10,),
            if(sentByMe)
            Text(
              time!,
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


}


class RandomColorModel {
  Random random = Random();
  Color getColor() {
    return Color.fromARGB(255, random.nextInt(200),
        random.nextInt(200), random.nextInt(200));
  }
}



