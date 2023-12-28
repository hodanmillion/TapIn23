import 'package:get/get.dart';

import '../controller/PrivateChatController.dart';

class ChatViewBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut(() => PrivateChatController());

  }

}