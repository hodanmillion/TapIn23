
import '../model/message.dart';

abstract class UserMessageListRemoteSource {
  Stream<List<MessagePublicChat>> getAllMessages({String? groupId});
  Future<void> addAMessage({MessagePublicChat? messageEntity,String? groupId});
  Stream<List<MessagePublicChat>> getAllPastMessages({String? groupId,DateTime? time});

}
