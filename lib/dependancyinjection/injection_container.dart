import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:get/get.dart';
import 'package:myapp/controller/ContactController.dart';
import 'package:myapp/controller/PrivateChatController.dart';
import 'package:myapp/controller/past_chat_controller.dart';
import 'package:myapp/remote/chat_group_remote_resource.dart';
import 'package:myapp/remote/chat_group_remote_source_impl.dart';
import 'package:myapp/repository/chat_group_repo.dart';
import 'package:myapp/repository/chat_group_repo_impl.dart';
import 'package:myapp/usecases/create_chat_group_use_case.dart';
import 'package:myapp/usecases/get_past_message_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/UserController.dart';
import '../controller/chat_controller.dart';
import '../helpers/local_storage.dart';
import '../remote/user_messageList_remoute_source_impl.dart';
import '../remote/user_message_list_remote_source.dart';
import '../repository/user_list_messages_repo.dart';
import '../repository/user_messages_list_repo_impl.dart';
import '../usecases/add_message_usecase.dart';
import '../usecases/edit_group_use_case.dart';
import '../usecases/get_messages_usecase.dart';

Future<void> init() async {
  Get.lazyPut<ChatController>(() => ChatController(
        addMessages: Get.find<AddMessageUseCase>(),
        getMessages: Get.find<GetMessagesUseCase>(),
    editGroup: Get.find<EditGroupUseCase>(),
    createGroup: Get.find<CreateChatGroupUseCase>()
      ));
  Get.lazyPut(() => ChatController());

  Get.lazyPut<PastChatListController>( () => PastChatListController(
      getMessages: Get.find<GetPastMessagesUseCase>(),
  ));

  Get.lazyPut(() => ContactsController());
  Get.lazyPut(() => PrivateChatController());
  Get.lazyPut(() => UserController());

//  Chat usecase:


  Get.lazyPut<AddMessageUseCase>(() => AddMessageUseCase(
        userListMessagesRepo: Get.find<UserListMessagesRepo>(),
      ));

  Get.lazyPut<GetPastMessagesUseCase>(
          () => GetPastMessagesUseCase(repository: Get.find<UserListMessagesRepo>()));


  Get.lazyPut<GetMessagesUseCase>(
      () => GetMessagesUseCase(repository: Get.find<UserListMessagesRepo>()));
  
  Get.lazyPut<EditGroupUseCase>(() => EditGroupUseCase(
    chatGroupRepo: Get.find<ChatGroupRepo>(),
  ));

  Get.lazyPut<CreateChatGroupUseCase>(
          () => CreateChatGroupUseCase(chatGroupRepo: Get.find<ChatGroupRepo>()));

  //REPOS


  Get.lazyPut<UserListMessagesRepo>(() => UserMessagesListRepoImplementation(
      userMessageListRemoteSource: Get.find<UserMessageListRemoteSource>()));
  Get.lazyPut<ChatGroupRepo>(() => ChatGroupRepoImplementation(
      chatGroupRemoteSource:  Get.find<ChatGroupRemoteSource>()));

  //DATA SOURCE


  //Chat Source

  Get.lazyPut<UserMessageListRemoteSource>(
    () => UserMessageListRemoteSourceImplementation(
      firestore: Get.find<FirebaseFirestore>(),
    ),
  );

  Get.lazyPut<ChatGroupRemoteSource>(
        () => ChatGroupRemoteSourceImplementation(
      firebaseAuth: Get.find<FirebaseAuth>(),
          geo: Get.find<GeoFlutterFire>(), firestore: Get.find<FirebaseFirestore>()
    ),
  );
  Get.putAsync<SharedPreferences>(() => SharedPref.init());

//EXTERNAL
  final fireStore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final geo = GeoFlutterFire();

  Get.put(auth, permanent: true);
  Get.put(fireStore, permanent: true);
  Get.put(geo, permanent: true);

}
