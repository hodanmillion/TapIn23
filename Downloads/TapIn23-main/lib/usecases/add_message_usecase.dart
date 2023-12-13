
import '../model/message.dart';
import '../repository/user_list_messages_repo.dart';

class AddMessageUseCase {
  final UserListMessagesRepo userListMessagesRepo;

  AddMessageUseCase({required this.userListMessagesRepo});

  Future<void> call({MessagePublicChat? message,String? groupId}) {
    print("===call");
    return userListMessagesRepo.addAMessage(messageEntity: message!,groupId: groupId);
  }
}
