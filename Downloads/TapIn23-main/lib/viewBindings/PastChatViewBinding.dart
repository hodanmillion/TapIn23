import 'package:get/get.dart';
import 'package:myapp/controller/past_chat_controller.dart';

import '../repository/user_list_messages_repo.dart';
import '../usecases/get_past_message_usecase.dart';

class PastChatViewBinding extends Bindings
{

  @override
  void dependencies() {
    Get.lazyPut(() => PastChatListController(getMessages:
    Get.put(GetPastMessagesUseCase(repository:Get.find<UserListMessagesRepo>()))));

  }
}