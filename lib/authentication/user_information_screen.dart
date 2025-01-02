import 'dart:io';

import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/utilities/global_methods.dart';
import 'package:chat_app_flutter/widgets/app_bar_back_button.dart';
import 'package:chat_app_flutter/widgets/display_user_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

class UserInformationScreen extends StatefulWidget {
  const UserInformationScreen({super.key});

  @override
  State<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends State<UserInformationScreen> {
  final TextEditingController _nameController = TextEditingController();

  File? finalFileImage;
  String userImage = '';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void selectUserImage(bool fromCamera) async {
    finalFileImage = await pickImage(
        fromCamera: fromCamera,
        onFail: (String message) {
          showSnackBar(
            context,
            message,
          );
        });

    // crop the image
    await cropImage(finalFileImage?.path);

    popContext();
  }

  popContext() {
    Navigator.pop(context);
  }

  Future<void> cropImage(filePath) async {
    if (filePath != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: filePath,
        maxWidth: 800,
        maxHeight: 800,
        compressQuality: 90,
      );
      if (croppedFile != null) {
        setState(() {
          finalFileImage = File(croppedFile.path);
        });
      }
    }
  }

  void showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height / 7,
        child: Column(
          children: [
            ListTile(
              onTap: () {
                selectUserImage(true);
              },
              leading: const Icon(
                Icons.camera_alt,
                color: Colors.blue,
              ),
              title: const Text('Camera'),
            ),
            ListTile(
              onTap: () {
                selectUserImage(false);
              },
              leading: const Icon(
                Icons.image,
                color: Colors.blue,
              ),
              title: const Text('Thư viện'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        // centerTitle: true,
        title: const Text('Thông tin cá nhân'),
        // delete the shadow
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade300,
            height: 1.0,
          ),
        ),
      ),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          children: [
            DisplayUserImage(
              finalFileImage: finalFileImage,
              radius: 60,
              onPressed: () {
                showBottomSheet();
              },
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Nhập tên',
                hintStyle: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                labelText: 'Nhâp tên',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isEmpty ||
                        _nameController.text.length < 3) {
                      showSnackBar(
                        context,
                        'Vui lòng nhập tên từ 3 ký tự trở lên',
                      );
                      return;
                    }
                    // save user data to firestore
                    saveUserDataToFireStore();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Tiếp tục',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
            ),
          ],
        ),
      )),
    );
  }

  // save user data to firestore
  void saveUserDataToFireStore() async {
    final authProvide = context.read<AuthenticationProvider>();

    UserModel userModel = UserModel(
      uid: authProvide.uid!,
      name: _nameController.text.trim(),
      phoneNumber: authProvide.phoneNumber!,
      image: '',
      token: '',
      aboutMe: 'Xin chào tôi là ${_nameController.text.trim()}',
      lastSeen: '',
      createdAt: '',
      isOnline: true,
      friendsUIDs: [],
      friendRequestsUIDs: [],
      sentFriendRequestsUIDs: [],
    );

    authProvide.saveUserDataToFireStore(
      userModel: userModel,
      fileImage: finalFileImage,
      onSuccess: () async {
        showSnackBar(
          context,
          'Đăng ký tài khoản thành công',
        );
        await authProvide.saveUserDataToSharedPreferences();

        navigateToHomeScreen();
      },
      onFail: () async {
        showSnackBar(
          context,
          'Đăng ký tài khoản thất bại',
        );
      },
    );
  }

  void navigateToHomeScreen() {
    // navigate to home screen and remove all previous screens
    Navigator.of(context).pushNamedAndRemoveUntil(
      Constants.homeScreen,
      (route) => false,
    );
  }
}
