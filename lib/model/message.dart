class MessagePublicChat {
  final String senderId;
  final String senderEmail;
  final String message;
  final DateTime timestamp;
  final String gifUrl;
  final bool isGif;

  MessagePublicChat(
      {required this.senderId,
      required this.senderEmail,
      required this.message,
      required this.timestamp,
      required this.gifUrl,
      required this.isGif});

  //convert to map

  Map<String, dynamic> toMap() {
    return {
      'sender': senderId,
      'sendername': senderEmail,
      'message': message,
      'time': timestamp,
      'gifUrl': gifUrl,
      'isGif': isGif,
    };
  }
}
