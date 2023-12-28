
import '../model/message.dart';
import '../repository/user_list_messages_repo.dart';

class GetMessagesUseCase {
  final UserListMessagesRepo repository;
  GetMessagesUseCase({required this.repository});

  Stream<List<MessagePublicChat>> call({String? groupId}) {
    return repository.getAllMessages(groupId: groupId);
  }
}
