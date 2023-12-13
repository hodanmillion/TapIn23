import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:location/location.dart';
import 'package:myapp/model/message.dart';

class PublicChatService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
var groupId="";
  //SEND MDG

  // reference for our collections
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection("users");
  final CollectionReference groupCollection =
      FirebaseFirestore.instance.collection("public_chats");
  final geo = GeoFlutterFire();

  // creating a group
  Future createGroup(double lat, double lang,Location location) async {
    try {
      GeoFirePoint userLocation = geo.point(latitude: lat, longitude: lang);

      var groupId = lat.toString() + lang.toString();
      await groupCollection.doc(groupId).set({
        "groupName": "Chats",
        "admin":
        "${_firebaseAuth.currentUser!.uid}_${_firebaseAuth.currentUser!
            .email?.substring(0,6)}",
        "members":
        FieldValue.arrayUnion(["${_firebaseAuth.currentUser!.email?.substring(0,6)}"]),
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

  Stream<List<DocumentSnapshot>>nearestGroup(double lat, double lang) {
    GeoFirePoint location = geo.point(latitude: lat, longitude: lang);
    return geo.collection(collectionRef: groupCollection).within(
        center: location, radius: 0.5, field: 'position', strictMode: true);
  }

  createOrAddInGroup(double lat, double lang,Location location) {
    nearestGroup(lat, lang).listen((event) {
      print("nearestgroup==="+event.length.toString());
      if (event.isNotEmpty) {
      //  event[0];
        print("IDD==" + event[0]['groupId']);
        groupId=event[0]['groupId'];
        print("==groupid edit="+groupId);

        editGroup(lat, lang, (lat.toString() + lang.toString()));
      } else {
        createGroup(lat, lang,location);
      }
    });
  }

  Future editGroup(double lat, double lang, String groupId) async {
    try {

      groupCollection.doc(groupId).set({
        "members":
        FieldValue.arrayUnion(["${_firebaseAuth.currentUser! .email?.substring(0,6)}"]),
      });
      DocumentSnapshot documentSnapshot =
      await groupCollection.doc(groupId).get();
      var data= documentSnapshot.data();

    }catch(e){
      print("editobject=="+e.toString());
    }

  }
  Future removeUser(String groupId,String userName) async{
    DocumentReference groupDocumentReference = groupCollection.doc(groupId);
    groupDocumentReference.update({
      "members":FieldValue.arrayRemove(["${_firebaseAuth.currentUser! .email?.substring(0,6)}"])

    });
  }

// getting the chats
  getChats(String groupId) async {
    print("==groupid="+groupId);
    return groupCollection
        .doc(groupId)
        .collection("messages")
        .orderBy("time")
        .snapshots();
  }

  // send message
  sendMessage(String groupId, Map<String, dynamic> chatMessageData) async {
    groupCollection.doc(groupId).collection("messages").add(chatMessageData);
    groupCollection.doc(groupId).update({
      "recentMessage": chatMessageData['message'],
      "recentMessageSender": chatMessageData['sender'],
      "recentMessageTime": chatMessageData['time'].toString(),
    });
  }
}
