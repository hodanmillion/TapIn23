import 'package:flutter/material.dart';
import 'package:myapp/utils/colors.dart';

Future<void> showUploadOption(
    BuildContext context,
    VoidCallback handleGallery,
    VoidCallback handleCamera,
    bool showCamera,
    ) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Upload an Image',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextButton(
              onPressed: handleGallery,
              child: Text(
                'Choose from Gallery',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            if (showCamera)
              TextButton(
                onPressed: handleCamera,
                child: Text(
                  'Take a Photo',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );

    },
  );
}