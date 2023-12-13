import 'package:cloud_firestore/cloud_firestore.dart';

import 'message.dart';

class GroupModel {
  final String groupId;
  final int status;
  final String groupName;

  GroupModel({required this.groupId, required this.status, required this.groupName});

  //convert to map

  static GroupModel fromJson(DocumentSnapshot json) {
    return GroupModel(
        groupId: json.get('groupId'),
        status:json.get('status'),
        groupName: json.get('groupName'),
    );
  }

}