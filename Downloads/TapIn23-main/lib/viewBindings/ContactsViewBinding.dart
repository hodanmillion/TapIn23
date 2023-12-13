import 'package:get/get.dart';

import '../controller/ContactController.dart';

class ContactsViewBinding extends Bindings
{

  @override
  void dependencies() {
    Get.lazyPut(() => ContactsController());

  }
}