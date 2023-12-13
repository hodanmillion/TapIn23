import 'package:flutter/material.dart';
import 'package:myapp/services/firestore/firestore.dart';
import 'package:myapp/utils/colors.dart';

class MessageTile extends StatelessWidget {
  final String message;
  final String sender;
  final bool sentByMe;
  final String? gifUrl;
  final bool? isGif;

  const MessageTile({
    Key? key,
    required this.message,
    required this.sender,
    required this.sentByMe,
    required this.gifUrl,
    required this.isGif,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Building MessageTile: $message, sentByMe: $sentByMe');

    return Align(
      alignment: sentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: sentByMe ? AppColors.primaryColor : Colors.grey[300],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: FirestoreDB().getUserDataByEmail(sender),
              builder: (context, snapshot) {
                // Handle different states
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Loading...');
                } else if (snapshot.hasError) {
                  return Text('Error loading user data');
                }

                // Use the null-aware operator to access data safely
                final userData = snapshot.data?.data();

                // Check if data is null or username is not available
                if (userData == null || !userData.containsKey('username')) {
                  return Text('User data not available');
                }

                // Display the username
                return Text(
                  sentByMe ? 'you' : userData['username'] ?? 'Username not available',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                );
              },
            ),
            if (isGif != null && isGif!) // Check if gifUrl is not null
              SizedBox(
                width: 150, // Adjust the width as needed
                child: Image.network(
                  gifUrl!,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading GIF: $error');
                    return Text('Error loading GIF');
                  },
                  width: 150, // Adjust the width as needed
                ),
              ),
            Text(
              message ?? 'No message',
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

