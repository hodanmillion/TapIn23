import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/utils/spHelper.dart';

import '../model/message_chat.dart';

class PrivateChatController extends GetxController {
  FirebaseAuth? firebaseAuth = null;
  FirebaseFirestore? fireStore = null;
  RxList<Message> messages = RxList<Message>();
  RxString username = "".obs;
  RxString userurl = "".obs;
  RxString email = "".obs;
  RxList<String> messagesId = RxList<String>();
  RxBool isSendMessage = false.obs;
  final messageController = TextEditingController().obs;
  final searchGifText = TextEditingController().obs;
    RxBool isTyping = false.obs;
    RxString receiverUsername = ''.obs;

RxString selectedImageUrl = ''.obs;

void setSelectedImageUrl(String imageUrl) {
  selectedImageUrl.value = imageUrl;
}

void clearSelectedImageUrl() {
  selectedImageUrl.value = '';
}




  Future<void> sendMessage(String receiverId, String message) async {
  // Get current user info
  final String currentUserId = firebaseAuth!.currentUser!.uid;
  final String currentUserEmail = firebaseAuth!.currentUser!.email.toString();
  final Timestamp timestamp = Timestamp.now();
  final CollectionReference groupCollection =
  FirebaseFirestore.instance.collection("chat_rooms");

  // Trim the message to avoid sending empty spaces
  String trimmedMessage = message.trim();

  // Check if the trimmed message is not empty
  if (trimmedMessage.isNotEmpty || selectedGifUrl.value.isNotEmpty) {
    // Create a new message
    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      timestamp: timestamp,
      message: trimmedMessage,
      gifUrl: selectedGifUrl.value,
      isGif: selectedGifUrl.value.isNotEmpty,
    );

    // Construct chat room id from current user id and receiver id
    searchGifText.value.text = "";
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");
    print("=====image gallary--" + selectedGifUrl.value);

    // Add the new message to the database
    await fireStore!
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    await groupCollection.doc(chatRoomId).set({
      "lastMsg": selectedGifUrl.value.isNotEmpty ? "📷"  : trimmedMessage,
      "time":timestamp,
      firebaseAuth!.currentUser!.uid : true
    });

  }
}

  Stream<DocumentSnapshot<Map<String, dynamic>>> userChatData(
      String chatroomId,String id) {
    return FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatroomId)
        .collection('messages')
        .doc(id)
        .snapshots();
  }

  //GET MSG
  getMessageRoomID(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");
    print("====romm id--" + chatRoomId);
    return chatRoomId;
  }
  Stream<DocumentSnapshot<Map<String, dynamic>>> userDataStream(String uid) {
    return FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(uid)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userLocationStreem(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots();
  }

  getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    var query = fireStore!
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false);

    var message = query.snapshots().map((querySnap) {
      return querySnap.docs
          .map((docSnap) => Message.fromJson(docSnap))
          .toList();
    });

    var messageId = query.snapshots().map((querySnap) {
      return querySnap.docs
          .map((docSnap) => docSnap.id.toString())
          .toList();
    });

    messagesId.bindStream(messageId);
    messages.bindStream(message);

    FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserId)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        final test = documentSnapshot.data() as Map;
        username.value  = test['username'] ?? "";
        userurl.value  = test['proImage'] ?? "";
        email.value  = test['email'] ?? "";
       }

    });
  }

  Future<void> getUserLocation(String userId) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (documentSnapshot.exists) {
        GeoPoint? location = documentSnapshot.get('location') as GeoPoint?;
        final double latitude = location!.latitude;
        final double longitude = location.longitude;
        final List<Placemark> placemarks =
            await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final Placemark placemark = placemarks.first;
          final String address =
              "${placemark.locality}, ${placemark.administrativeArea}";
          userLocation.value = address;
        }
      }
    } catch (e) {
      print('Error retrieving user location: $e');
    }
  }

  Future<bool> checkIfContacts() async {
    final currentUserUid = firebaseAuth!.currentUser?.uid;
    if (currentUserUid != null) {
      final contactsQuery = FirebaseFirestore.instance
          .collection('contacts')
          .where('userId', isEqualTo: currentUserUid)
          .where('contactId', isEqualTo: receiverUserID);

      final contactsSnapshot = await contactsQuery.get();

      print("Number of contacts found: ${contactsSnapshot.docs.length}");

      return contactsSnapshot.docs.isNotEmpty;
    }
    print("Current user UID is null.");
    return false;
  }

  var receiverUserID = "".obs;
  var receiverUserEmail = "".obs;
  var senderId = "".obs;

  RxString userLocation = ''.obs;
  RxString emailP = ''.obs;
  RxString userNameP = ''.obs;
  RxString userImageP = ''.obs;
  RxString isMainUSerP = ''.obs;

  RxList<String> gifUrl = RxList<String>();

  String searchGifString = "";

  static const String apiKey =
      'l1WfAFgqA5WupWoMaCaWKB12G54J6LtZ'; // Replace with your GIPHY API key
  static const String endpoint =
      'https://api.giphy.com/v1/gifs/trending?api_key=$apiKey&limit=10';

  RxList<String> titleGif = RxList<String>();

  RxString selectedGifUrl = ''.obs;

  RxBool isSeachActive = false.obs;

  cancelSearch() {
    isSeachActive.value = false;
    gifUrl.clear();
    titleGif.clear();
    fetchGifs();
    searchGifText.value.text = "";
  }

  searchByGifName() async {
    isSeachActive.value = true;
    final response = await http.get(Uri.parse(
        'https://api.giphy.com/v1/gifs/search?api_key=$apiKey&limit=10&q=${searchGifText.value.text.toString().trim()}'));
    if (response.statusCode == 200) {
      gifUrl.clear();
      titleGif.clear();
      final data = json.decode(response.body);
      gifUrl.addAll(List<String>.from(
          data['data'].map((x) => x['images']['original']['url'])));
      titleGif.addAll(List<String>.from(data['data'].map((x) => x['title'])));
    } else {
      throw Exception('Failed to load GIFs');
    }
  }

  fetchGifs() async {
    final response = await http.get(Uri.parse(endpoint));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      gifUrl.addAll(List<String>.from(
          data['data'].map((x) => x['images']['original']['url'])));

      titleGif.addAll(List<String>.from(data['data'].map((x) => x['title'])));
    } else {
      throw Exception('Failed to load GIFs');
    }
  }

  Future<bool?> updateReadMessage(
      {required String doc, required bool isRead}) async {
    try {
      final user = firebaseAuth!.currentUser;
      if (user != null) {
        final currentUserUid = user.uid;
        // Query for unread messages in the 'contacts' collection
        final unreadMessagesQuery = FirebaseFirestore.instance
            .collection('accepted_c')
            .doc(doc)
            .collection('contacts')
            .doc(currentUserUid)
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
    firebaseAuth = FirebaseAuth.instance;
    fireStore = FirebaseFirestore.instance;
    AppSharedPrefs.spClean();
    receiverUserID.value = Get.parameters["receiverUserID"] != null ? Get.parameters["receiverUserID"]! : "" ;
    receiverUserEmail.value = Get.parameters["receiverUserEmail"] != null ? Get.parameters["receiverUserEmail"]! : "" ;
    senderId.value = Get.parameters["senderId"] != null ? Get.parameters["senderId"]! : "" ;

    getUserLocation(receiverUserID.value);
    getMessages(firebaseAuth!.currentUser!.uid, receiverUserID.value);

    fetchGifs();
  }
}