import 'package:location/location.dart';

import '../remote/chat_group_remote_resource.dart';
import 'chat_group_repo.dart';

class ChatGroupRepoImplementation implements ChatGroupRepo {
  ChatGroupRemoteSource chatGroupRemoteSource;
  ChatGroupRepoImplementation(
      {required this.chatGroupRemoteSource});

  @override
  Future<void> createGroup({double? lat, double? lang, Location? location,String? groupName}) async {
    chatGroupRemoteSource.createGroup(lat: lat!,lang: lang!,location: location!,groupName: groupName!);
  }

  @override
  Future<void> editGroup({double? lat, double? lang, String? groupId}) async {
    chatGroupRemoteSource.editGroup(lat: lat!,lang: lang!,groupId: groupId!);
  }

}
