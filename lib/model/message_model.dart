import 'package:cloud_firestore/cloud_firestore.dart';

import 'message.dart';

class MessageModel extends MessagePublicChat {
  MessageModel({
    required String? senderId,
    required String? senderEmail,
    required String? message,
    required DateTime? timestamp,
    required String? gifUrl,
    required bool? isGif,
  }) : super(
          senderId: senderId!,
          senderEmail: senderEmail!,
          message: message!,
          timestamp: timestamp!,
          gifUrl: gifUrl!,
          isGif: isGif!,
        );

  // This is where we define from json and to json methods.

  static MessageModel fromJson(DocumentSnapshot json) {
    try {
      DateTime? dt;

      // Get the data from the DocumentSnapshot
      final Map<String, dynamic>? data = json.data() as Map<String, dynamic>?;

      // Check if 'time' field exists in the document
      if (data != null && data['time'] != null) {
        dt = (data['time'] as Timestamp).toDate();
      }

      // Check if 'sender', 'sendername', 'message', 'gifUrl', and 'isGif' fields exist
      return MessageModel(
        senderId: data?['sender'] as String? ?? '', // Provide a default value if null
        senderEmail: data?['sendername'] as String? ?? '', // Provide a default value if null
        message: data?['message'] as String? ?? '', // Provide a default value if null
        gifUrl: data?['gifUrl'] as String? ?? '', // Provide a default value if null
        isGif: data?['isGif'] as bool? ?? false, // Provide a default value if null
        timestamp: dt,
      );
    } catch (e) {
      // Handle exceptions, e.g., log the error or return a default value
      print('Error parsing MessageModel: $e');
      return MessageModel(
        senderId: '',
        senderEmail: '',
        message: 'Error parsing message',
        timestamp: null,
        gifUrl: '',
        isGif: false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "sender": senderId,
      "sendername": senderEmail,
      "message": message,
      "time": timestamp,
      "gifUrl": gifUrl,
      "isGif": isGif,
    };
  }
}
