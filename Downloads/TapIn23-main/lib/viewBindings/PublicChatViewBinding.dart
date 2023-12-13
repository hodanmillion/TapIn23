import 'package:get/get.dart';
import 'package:myapp/controller/chat_controller.dart';

import '../usecases/add_message_usecase.dart';
import '../usecases/create_chat_group_use_case.dart';
import '../usecases/edit_group_use_case.dart';
import '../usecases/get_messages_usecase.dart';

class PublicChatViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ChatController(
        addMessages: Get.find<AddMessageUseCase>(),
        getMessages: Get.find<GetMessagesUseCase>(),
        editGroup: Get.find<EditGroupUseCase>(),
        createGroup: Get.find<CreateChatGroupUseCase>()));
  }
}
