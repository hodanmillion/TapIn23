import '../model/message.dart';
import '../repository/user_list_messages_repo.dart';

class GetPastMessagesUseCase {
  final UserListMessagesRepo repository;
  GetPastMessagesUseCase({required this.repository});

  Stream<List<MessagePublicChat>> call({String? groupId,DateTime? time}) {
    return repository.getAllPastMessages(groupId: groupId,time: time);
  }
}