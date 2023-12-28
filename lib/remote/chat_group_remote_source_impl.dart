
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:location/location.dart';

import 'chat_group_remote_resource.dart';

class ChatGroupRemoteSourceImplementation
    implements ChatGroupRemoteSource {
  final FirebaseFirestore firestore;
  ChatGroupRemoteSourceImplementation({required this.firestore,required this.firebaseAuth,required this.geo});
  final FirebaseAuth firebaseAuth ;
  final geo ;

  @override
  Future<void> createGroup({double? lat, double? lang, Location? location,String? groupName}) async{
    try {
      final groupCollection = firestore.collection("public_chats");

      GeoFirePoint userLocation = geo.point(latitude: lat!, longitude: lang!);

      var groupId = lat.toString() + lang.toString();
      await groupCollection.doc(groupId).set({
        "groupName": groupName,
        "admin":
        "${firebaseAuth.currentUser!.uid}_${firebaseAuth.currentUser!
            .email?.substring(0,6)}",
        "members":
        FieldValue.arrayUnion(["${firebaseAuth.currentUser!.email?.substring(0,6)}"]),
        "groupId": groupId,
        "recentMessage": "",
        "recentMessageSender": "",
        "position": userLocation.data
      });
      // update the members

      //   DocumentReference userDocumentReference = userCollection.doc(
      //       _firebaseAuth.currentUser!.uid);
      //   return await userDocumentReference.update({
      //     "groups":
      //     FieldValue.arrayUnion(["${groupDocumentReference.id}_$"])
      //   });
      // }
      groupId=groupId;
    }on Exception catch(exception){
      print("======exception"+exception.toString());

    }

    catch( e){

      print("==exception"+e.toString());
    }

  }

  @override
  Future<void> editGroup({double? lat, double? lang, String? groupId}) async{
    try {
      final groupCollection = firestore.collection("public_chats");

      groupCollection.doc(groupId).update({
        "members":
        FieldValue.arrayUnion(["${firebaseAuth.currentUser! .email?.substring(0,6)}"]),
      });
      DocumentSnapshot documentSnapshot =
          await groupCollection.doc(groupId).get();
      var data= documentSnapshot.data();

    }catch(e){
      print("editobject=="+e.toString());
    }

  }

}
