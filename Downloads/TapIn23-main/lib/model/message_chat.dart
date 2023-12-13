import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final String gifUrl;
  final bool isGif;

  Message(
      {required this.senderId,
      required this.senderEmail,
      required this.receiverId,
      required this.message,
      required this.timestamp,
      required this.gifUrl,
      required this.isGif});

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
    };
  }

  static Message fromJson(DocumentSnapshot json) {
    //  DateTime dt = (json.get('timestamp') as Timestamp).toDate();

    // var date = DateTime.fromMillisecondsSinceEpoch(json.get('datetime') * 1000);
    //   print("===giffff"+json.get('gifUrl'));
    return Message(
        senderId: json.get('senderId'),
        senderEmail: json.get('senderEmail'),
        message: json.get('message'),
        receiverId: json.get('receiverId'),
        timestamp: json.get('timestamp'),
        gifUrl: json.get('gifUrl'),
        isGif: json.get('isGif'));
  }
}
