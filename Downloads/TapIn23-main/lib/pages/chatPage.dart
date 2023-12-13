
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/controller/PrivateChatController.dart';
import 'package:intl/intl.dart';
import 'package:myapp/services/firestore/firestore.dart';
import 'package:myapp/services/notification/notification.dart';
import 'package:myapp/services/storage/fire_storage.dart';
import 'package:myapp/utils/image_select.dart';
import 'package:myapp/utils/upload_image_dialogue.dart';
import '../model/message_chat.dart';
import '../routes/app_route.dart';
import '../utils/colors.dart';
import 'package:flutter/services.dart';

// ignore: depend_on_referenced_packages
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends GetView<PrivateChatController> {
  final controller = Get.find<PrivateChatController>();
  int id = DateTime.now().millisecondsSinceEpoch;
  bool isChatOpen = true;

  final ScrollController _scrollController = ScrollController();
  final RxString maximizedImageUrl = ''.obs;

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
              style: TextStyle(
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
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }




 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      centerTitle: true,
      elevation: 1,
      title: FutureBuilder(
        future: FirestoreDB().getUserData(controller.receiverUserID.value),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Failed to fetch data'),
            );
          } else if (snapshot.data != null &&
              snapshot.data is Map<String, dynamic>) {
            // Check if snapshot.data is not null and is of the expected type
            Map<String, dynamic> userData =
                snapshot.data as Map<String, dynamic>;

            // Now you can safely access userData properties
            return InkWell(
              onTap: () {
                controller.emailP!.value = (userData['email'] as String?) ?? '';
                controller.userNameP!.value = userData['username'] ?? '';
                controller.userImageP!.value = userData['proImage'] ?? '';

                Get.toNamed(PageConst.userPrivateProfilePage);
              },
              child: Row(
                children: [
                  (userData['proImage'] != null)
                      ? Container(
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
                      : Icon(Icons.person_outline),
                  const SizedBox(width: 12),
                  Text(
                    userData['username'] ?? userData['email'],
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          } else {
            // Handle the case when snapshot.data is null or of unexpected type
            return Center(
              child: Text('Account Deleted'),
            );
          }
        },
      ),
      backgroundColor: Colors.black,
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildTextComposer(
            textController: controller.messageController.value,
            context: context,
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
      final reversedMessages = controller.messages.reversed.toList();
      return ListView.builder(
        reverse: true,
        controller: _scrollController,
        physics: BouncingScrollPhysics(),
        itemCount: reversedMessages.length,
        itemBuilder: (context, index) {
          return _buildMessageItem(reversedMessages[index]);
        },
      );
    });
  }

  Widget _buildMessageItem(Message document) {
  final String currentUserUid = controller.firebaseAuth!.currentUser!.uid;
  bool isUrl = document.message.contains(RegExp(r'http(s)?://'));

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
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (document.senderId == currentUserUid)
                        ? AppColors.primaryColor
                        : Colors.grey[300],
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: (document.senderId == currentUserUid)
                          ? const Radius.circular(20)
                          : const Radius.circular(0),
                      bottomRight: (document.senderId == currentUserUid)
                          ? const Radius.circular(0)
                          : const Radius.circular(20),
                    ),
                  ),
                  child: Column(
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
                            return Text('Loading...');
                          } else if (snapshot.hasError) {
                            return Text('User');
                          }

                          final username = snapshot.data?['username'];
                          return Text(
                            (document.senderId == currentUserUid)
                                ? 'You'
                                : username ?? 'Unknown User',
                            style: TextStyle(
                              color: (document.senderId == currentUserUid)
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      if (document.isGif)
                        Image.network(
                          document.gifUrl,
                          width: 150,
                        ),
                      const SizedBox(height: 5),
                      SelectableText(
                        sentence.trim(),
                        style: TextStyle(
                            color: (document.senderId == currentUserUid)
                                ? Colors.white
                                : Colors.black),
                      ),
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
                      builder: (context) => Container(
                        height: MediaQuery.of(context).size.height * 0.5,
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
                    onSubmitted: _handleSubmitted,
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
                    _handleSubmitted("");
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
        await FireBaseNoti().getUserToken(controller.receiverUserID.value);
    String senderId = controller.firebaseAuth!.currentUser!.uid;
    String senderUsername = await fetchSenderUsername(senderId);

    await FireBaseNoti().sendNotification(
      token,
      text.isNotEmpty ? text : controller.selectedGifUrl.value,
      'Message from $senderUsername',
      {
        'receiverUserEmail': controller.firebaseAuth!.currentUser?.email,
        'receiverUserID': controller.receiverUserID.value,
        'senderId': controller.firebaseAuth!.currentUser!.uid,
      },
    );

    closeChat();
  } catch (e) {
    print('Error sending message: $e');
    // Handle the error appropriately (e.g., show an error message to the user)
  }
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