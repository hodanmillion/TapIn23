import 'package:location/location.dart';

abstract class ChatGroupRemoteSource {
  Future<void> editGroup({double lat, double lang,String groupId});
  Future<void> createGroup({double lat, double lang,Location location,String groupName});
}