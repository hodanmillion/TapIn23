
import 'package:myapp/repository/user_list_messages_repo.dart';

import '../model/message.dart';
import '../remote/user_message_list_remote_source.dart';

class UserMessagesListRepoImplementation implements UserListMessagesRepo {
  UserMessageListRemoteSource userMessageListRemoteSource;
  UserMessagesListRepoImplementation(
      {required this.userMessageListRemoteSource});
  @override
  Future<void> addAMessage({MessagePublicChat? messageEntity,String? groupId}) =>
      userMessageListRemoteSource.addAMessage(messageEntity: messageEntity!,groupId: groupId);

  @override
  Stream<List<MessagePublicChat>> getAllMessages({String? groupId}) =>
      userMessageListRemoteSource.getAllMessages(groupId: groupId);

  @override
  Stream<List<MessagePublicChat>> getAllPastMessages({String? groupId, DateTime? time}) =>
      userMessageListRemoteSource.getAllPastMessages(groupId: groupId,time: time);


}
