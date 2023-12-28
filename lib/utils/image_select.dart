import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

Future<Uint8List?> handleImageUpload(ImageSource source) async {
  final ImagePicker picker = ImagePicker();
  // XFile image = await _picker.pickImage(...)
  XFile? pickedFile = await picker.pickImage(
    source: source,
    imageQuality: 30,
  );
  if (pickedFile == null) return null;
  return await pickedFile.readAsBytes();
}
