
import 'package:location/location.dart';
import 'package:myapp/repository/chat_group_repo.dart';

class CreateChatGroupUseCase{
  final ChatGroupRepo chatGroupRepo;

  CreateChatGroupUseCase({required this.chatGroupRepo});

  Future<void> call({double? lat, double? lang,Location? location,String? groupName}) {
    return chatGroupRepo.createGroup(lat: lat!,lang: lang!,location: location!,groupName: groupName!);
  }
}