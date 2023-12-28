import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:myapp/usecases/get_past_message_usecase.dart';

import '../model/message.dart';

class PastChatListController extends GetxController {
  GetPastMessagesUseCase? _getMessagesUseCase;


  PastChatListController({
    getMessages = GetPastMessagesUseCase,
  }) {
    _getMessagesUseCase = getMessages;
  }

  RxList<MessagePublicChat> messagesList = RxList<MessagePublicChat>();

  // List<MessagePublicChat> get messagesList => _messagesList;
  FirebaseAuth? _firebaseAuth = null;
  String groupId = '';
  String streetName = '';

  FirebaseAuth get firebaseAuth => _firebaseAuth!;

getMessagesListFromDB() {
  try {
    print("Fetching messages for groupId: $groupId");
    _getMessagesUseCase!.call(groupId: groupId,time: DateTime.now().subtract(Duration(days: 2))).listen((messages) {
      print("Received ${messages.length} messages: $messages");
      messagesList.assignAll(messages);
    }, onError: (error) {
      print("Error fetching messages: $error");
    });
  } catch (error) {
    print("Error fetching messages: $error");
  }
  print("==messagelist: ${messagesList.length}");
  // _messagesList.sort((a, b) => b.dateTime.compareTo(a.dateTime));
}




  @override
  void onInit() {
    super.onInit();
    _firebaseAuth = FirebaseAuth.instance;


    groupId = Get.parameters["groupId"]!;
    streetName = Get.parameters["streetname"]!;
    print("===groupId: $groupId");
    print("===streetName: $streetName");


    getMessagesListFromDB();
  }
}