import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:myapp/controller/PrivateChatController.dart';
import 'package:myapp/controller/past_chat_controller.dart';
import 'package:myapp/repository/user_list_messages_repo.dart';
import '../components/message_tile.dart'; // Adjust the import based on the actual location

class PastChatView extends GetView<PastChatListController> {
  final controller = Get.find<PastChatListController>();
  // final controller2 = Get.put(UserListMessagesRepo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        centerTitle: true,
        elevation: 1,
        title: Text(
          "Chats - ${controller.streetName}",
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: Container(
        child: Stack(
          children: <Widget>[
            Obx(() {
              controller.messagesList.value = controller.messagesList.reversed.toList();
              if (controller.messagesList.isNotEmpty) {
                return ListView.builder(
                  reverse: true,
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
                      time: _formatTimestamp(controller.messagesList[index].timestamp)
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

  String _formatTimestamp(DateTime timestamp) {
    final format = DateFormat('hh:mm a');
    return format.format(timestamp);
  }
}
