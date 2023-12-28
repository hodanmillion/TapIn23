import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/utils/colors.dart';

class ImageViewPage extends StatefulWidget {
  @override
  State<ImageViewPage> createState() => _ImageViewPageState();
}

class _ImageViewPageState extends State<ImageViewPage> {
  @override
  Widget build(BuildContext context) {
    final Map<String, String> params = Get.arguments;
    final String imageUrl = params['imageUrl'] ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Image View',
          style: TextStyle(color: Colors.white), // Customize text color
        ),
      ),
      body: Container(
        color: Colors.black, // Set the background color
        child: Center(
          child: CachedNetworkImage(
            placeholder: (context, url) => Center(
              // A custom loading indicator
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            errorWidget: (context, url, error) => Icon(
              Icons.error,
              color: Colors.red,
              size: 60.0,
            ),
            fit: BoxFit.cover,
            imageUrl: imageUrl,
          ),
        ),
      ),
    );
  }
}