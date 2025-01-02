import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/utilities/assets_manager.dart';
import 'package:date_format/date_format.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}

Widget userImageWidget({
  required String imageUrl,
  required double radius,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      backgroundImage: imageUrl.isNotEmpty
          // ? NetworkImage(imageUrl) mất Internet sẽ không hiển thị ảnh
          ? CachedNetworkImageProvider(
              imageUrl) // để tải hình ảnh từ một URL qua mạng và tự động lưu trữ (cache) hình ảnh đã tải về (Hình ảnh được hiển thị từ bộ nhớ cache, không cần tải lại từ mạng).
          : const AssetImage(AssetsManager.userImage) as ImageProvider,
    ),
  );
}

// pick image from gallery of camera
Future<File?> pickImage({
  required bool fromCamera,
  required Function(String) onFail,
}) async {
  File? fileImage;
  if (fromCamera) {
    // get picture from camera
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile == null) {
        onFail('Không có hình nào được chọn từ camera');
      } else {
        fileImage = File(pickedFile.path);
      }
    } catch (e) {
      onFail(e.toString());
    }
  } else {
    // get picture from gallery
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        onFail('Không có hình nào được chọn từ thư viện');
      } else {
        fileImage = File(pickedFile.path);
      }
    } catch (e) {
      onFail(e.toString());
    }
  }
  return fileImage;
}

// pick video from gallery
Future<File?> pickVideo({
  required Function(String) onFail,
}) async {
  File? fileVideo;
  try {
    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile == null) {
      onFail('Không có video nào được chọn từ thư viện');
    } else {
      fileVideo = File(pickedFile.path);
    }
  } catch (e) {
    onFail(e.toString());
  }

  return fileVideo;
}

Padding buildDateTime(groupByValue) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      formatDate(groupByValue.timeSent, [dd, '/', mm, '/', yyyy]),
      textAlign: TextAlign.center,
      style: GoogleFonts.openSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
    ),
  );
}

Widget messageToShow({
  required MessageEnum type,
  required String message,
}) {
  switch (type) {
    case MessageEnum.text:
      return Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    case MessageEnum.image:
      return const Row(
        children: [
          Icon(Icons.image_outlined),
          SizedBox(width: 10),
          Text(
            'Ảnh',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    case MessageEnum.video:
      return const Row(
        children: [
          Icon(Icons.video_library_outlined),
          SizedBox(width: 10),
          Text(
            'Video',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    case MessageEnum.file:
      return const Row(
        children: [
          Icon(Icons.audiotrack_outlined),
          SizedBox(width: 10),
          Text(
            'Audio',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    default:
      return Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
  }
}

// store file to storage and return file url
Future<String> storeFileToStorage({
  required File file,
  required String reference,
}) async {
  UploadTask uploadTask =
      FirebaseStorage.instance.ref().child(reference).putFile(file);
  TaskSnapshot taskSnapshot = await uploadTask;
  String fileUrl = await taskSnapshot.ref.getDownloadURL();
  return fileUrl;
}
