import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:myapp/usecases/get_past_message_usecase.dart';

import '../model/message.dart';

class PastChatListController extends GetxController {
  GetPastMessagesUseCase? _getMessagesUseCase;

  PastChatListController({
    getMessages = GetPastMessagesUseCase,

    // signUpUseCase: SignUpUseCase,
  }) {
    _getMessagesUseCase = getMessages;
  }

  RxList<MessagePublicChat> _messagesList = RxList<MessagePublicChat>();

  List<MessagePublicChat> get messagesList => _messagesList;
  FirebaseAuth? _firebaseAuth = null;
  String groupId = '';
  String streetName = '';

  FirebaseAuth get firebaseAuth => _firebaseAuth!;

  getMessagesListFromDB() {
    _messagesList.bindStream(_getMessagesUseCase!.call(groupId: groupId));
    print("==messagelist" + _messagesList.length.toString());
    // _messagesList.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  void onInit() {
    super.onInit();
    _firebaseAuth = FirebaseAuth.instance;

    groupId = Get.parameters["groupId"]!;
    streetName = Get.parameters["streetname"]!;

    print("===groupId" + groupId);
    print("===streetName" + streetName);
    getMessagesListFromDB();
  }
}