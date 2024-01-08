import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/controller/chat_controller.dart';
import 'package:myapp/utils/colors.dart';
import '../routes/app_route.dart';
import '../services/firestore/firestore.dart';

class PastChatListPage extends GetView<ChatController> {
  final controller = Get.find<ChatController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Obx(
          () => controller.groupListModel.isEmpty
              ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(40),
                    topLeft: Radius.circular(40),
                  ),
                  border: Border.all(
                    width: 3,
                    color: Colors.white,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Text(
                    "No past chat history is available!".toUpperCase(),
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xff24786D)),
                  ),
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(40),
                    topLeft: Radius.circular(40),
                  ),
                  border: Border.all(
                    width: 3,
                    color: Colors.white,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Public Chat History".toUpperCase(),
                            style: GoogleFonts.openSans(
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 60),
                        itemCount: controller.groupListModel.length,
                        itemBuilder: (context, index) {
                          print(
                              "Group Name: ${controller.groupListModel[index].groupName}");
                          return GestureDetector(
                            onTap: () {
                              var param = {
                                "groupId": controller
                                    .groupListModel[index].groupId,
                                "streetname": controller
                                    .groupListModel[index].groupName,
                              };
                              Get.toNamed(PageConst.pastChatView,
                                  parameters: param);
                            },
                            child: Card(
                              elevation: 0,
                              margin: const EdgeInsets.all(5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  controller
                                      .groupListModel[index].groupName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
        ),
        floatingActionButton: GestureDetector(
          onTap: () async {
            controller.getUserLocation();
            String uid = FirebaseAuth.instance.currentUser!.uid;
            final data = await FirestoreDB().getUserData(uid);
            print('data we need: $data');
            Get.toNamed(PageConst.autoGeneratedChatPage, parameters: {
              'username': 'T',
            });
          },
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            elevation: 8,

            child: Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(

                    border: Border.all(color: AppColors.primaryColor),
                    shape: BoxShape.circle,
                    /*image: const DecorationImage(

                        image: AssetImage(
                            "images/img_2.png"))*/),child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Image.asset("images/groupchat_icon.png",fit: BoxFit.cover),
                            )),
          ),
        )
        );
  }

  void onPressed() {}
}

/*FloatingActionButton(

        backgroundColor: const Color(0xffffffff),
        onPressed: () async {
          String uid = FirebaseAuth.instance.currentUser!.uid;
          final data = await FirestoreDB().getUserData(uid);
          print('data we need: $data');
          Get.toNamed(PageConst.autoGeneratedChatPage, parameters: {
            'username': 'T',
          });
        },
        child: ,
      ),*/