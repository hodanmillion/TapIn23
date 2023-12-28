import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/remote/user_message_list_remote_source.dart';

import '../model/message.dart';
import '../model/message_model.dart';

class UserMessageListRemoteSourceImplementation
    implements UserMessageListRemoteSource {
  final FirebaseFirestore firestore;

  UserMessageListRemoteSourceImplementation({required this.firestore});

  @override
  Future<void> addAMessage(
      {MessagePublicChat? messageEntity, String? groupId}) async {
    final messageCollectionRef = firestore.collection("public_chats");
    final userCollection = firestore.collection("users");

    var messageId = messageCollectionRef.doc().id;
    print("groupid=" + groupId!);
    if (groupId!.isNotEmpty) {
      print("groupid not empty"+messageEntity!.gifUrl.toString());

      messageCollectionRef.doc(groupId).collection("message").add(MessageModel(
            senderEmail: messageEntity!.senderEmail,
            message: messageEntity.message,
            senderId: messageEntity.senderId,
            timestamp: messageEntity.timestamp,
            gifUrl: messageEntity.gifUrl,
            isGif: messageEntity.isGif,
          ).toJson());
      messageCollectionRef.doc(groupId).update({
        "recentMessage": messageEntity.message,
        "recentMessageSender": messageEntity.senderId,
        "recentMessageTime": messageEntity.timestamp,
      });
    }
    //Status 1= Active 0 = InActive
  }

  @override
  Stream<List<MessagePublicChat>> getAllMessages({String? groupId}) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final messages = firestore
        .collection("public_chats")
        .doc(groupId)
        .collection("message")
        .orderBy("time", descending: false)
        .where("time", isGreaterThan: yesterday);

    return messages.snapshots().map((querySnap) {
      return querySnap.docs
          .map((docSnap) => MessageModel.fromJson(docSnap))
          .toList();
    });
  }

  @override
  Stream<List<MessagePublicChat>> getAllPastMessages(
      {String? groupId, DateTime? time}) {
    var timeAfterTwoDays = time?.add(const Duration(days: 2));
    final messages = firestore
        .collection("public_chats")
        .doc(groupId)
        .collection("message")
        .orderBy("time", descending: false)
        .where("time",
            isGreaterThanOrEqualTo: time,
            isLessThanOrEqualTo: timeAfterTwoDays);

    return messages.snapshots().map((querySnap) {
      return querySnap.docs
          .map((docSnap) => MessageModel.fromJson(docSnap))
          .toList();
    });
  }
}
