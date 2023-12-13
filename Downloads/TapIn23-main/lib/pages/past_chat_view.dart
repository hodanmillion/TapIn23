import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/controller/past_chat_controller.dart';
import '../components/message_tile.dart'; // Adjust the import based on the actual location

class PastChatView extends GetView<PastChatListController> {
  final controller = Get.find<PastChatListController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 1,
        title: Text(
          "Chats - ${controller.streetName}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Container(
        child: Stack(
          children: <Widget>[
            Obx(() {
              if (controller.messagesList.isNotEmpty) {
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 60),
                  itemCount: controller.messagesList.length,
                  itemBuilder: (context, index) {
                    return MessageTile(
                      message: controller.messagesList[index].message,
                      sender: controller.messagesList[index].senderEmail,
                      sentByMe: controller.firebaseAuth.currentUser?.uid ==
                          controller.messagesList[index].senderId,
                      gifUrl: controller.messagesList[index].gifUrl,
                      isGif: controller.messagesList[index].isGif,
                    );
                  },
                );
              } else {
                // Add a placeholder or message when there are no messages
                return Container(
                  alignment: Alignment.center,
                  child: Text("No messages available."),
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}
