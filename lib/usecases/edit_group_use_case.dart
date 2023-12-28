import 'package:myapp/repository/chat_group_repo.dart';

class EditGroupUseCase {
  final ChatGroupRepo chatGroupRepo;

  EditGroupUseCase({required this.chatGroupRepo});

  Future<void> call({double? lat, double? lang, String? groupId}) {
    return chatGroupRepo.editGroup(lat: lat!,lang: lang!,groupId: groupId!);
  }
}