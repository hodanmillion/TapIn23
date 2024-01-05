import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final String gifUrl;
  final bool isGif;
  String? like;
  String? id;

  Message(
      {required this.senderId,
      required this.senderEmail,
      required this.receiverId,
      required this.message,
      required this.timestamp,
      required this.gifUrl,
      required this.isGif,
      this.like,
      this.id});

  //convert to map

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'gifUrl': gifUrl,
      'isGif': isGif,
      'like': like ?? "0",
      'id': id
    };
  }

  static Message fromJson(DocumentSnapshot json, String id) {
    //  DateTime dt = (json.get('timestamp') as Timestamp).toDate();

    // var date = DateTime.fromMillisecondsSinceEpoch(json.get('datetime') * 1000);
    //   print("===giffff"+json.get('gifUrl'));
    final like = json.data() as Map<String, dynamic>;
    return Message(
        senderId: json.get('senderId'),
        senderEmail: json.get('senderEmail'),
        message: json.get('message'),
        receiverId: json.get('receiverId'),
        timestamp: json.get('timestamp'),
        gifUrl: json.get('gifUrl'),
        isGif: json.get('isGif'),
        like: like["like"] == null ? '0' : json.get("like"),
        id: id);
  }
}

class Contact {
  final String contactId;
  final String email;
  final String profileImg;
  final String userId;
  final Timestamp? timestamp;
  final String username;
  final bool isRead;

  Contact({
    required this.contactId,
    required this.email,
    required this.profileImg,
    required this.userId,
    required this.timestamp,
    required this.username,
    required this.isRead,
  });

  Map<String, dynamic> toMap() {
    return {
      'contactId': contactId,
      'email': email,
      'proImage': profileImg,
      'userId': userId,
      'time': timestamp,
      'username': username,
      'isRead': isRead,
    };
  }

  static Contact fromJson(DocumentSnapshot json) {
    final like = json.data() as Map<String, dynamic>;
    return Contact(
      contactId: json.get('contactId'),
      email: json.get('email'),
      userId: json.get('userId'),
      profileImg: json.get('proImage'),
      timestamp: like["time"] == null ? null : json.get("time"),
      username: json.get('username'),
      isRead: json.get('isRead'),
    );
  }
}
