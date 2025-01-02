import 'dart:io';

import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/models/group_model.dart';
import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/providers/group_provider.dart';
import 'package:chat_app_flutter/utilities/global_methods.dart';
import 'package:chat_app_flutter/widgets/app_bar_back_button.dart';
import 'package:chat_app_flutter/widgets/display_user_image.dart';
import 'package:chat_app_flutter/widgets/friends_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  // group name controller
  final TextEditingController groupNameController = TextEditingController();
  // group description controller
  final TextEditingController groupDescriptionController =
      TextEditingController();
  File? finalFileImage;
  String userImage = '';

  void selectImage(bool fromCamera) async {
    finalFileImage = await pickImage(
      fromCamera: fromCamera,
      onFail: (String message) {
        showSnackBar(context, message);
      },
    );

    // crop image
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
        maxHeight: 800,
        maxWidth: 800,
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
      builder: (context) => SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: () {
                selectImage(true);
              },
              leading: const Icon(
                Icons.camera_alt,
                color: Colors.blue,
              ),
              title: const Text('Camera'),
            ),
            ListTile(
              onTap: () {
                selectImage(false);
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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    groupNameController.dispose();
    groupDescriptionController.dispose();
    super.dispose();
  }

  // tạo nhóm
  void createGroup() {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    final groupProvider = context.read<GroupProvider>();

    // kiểm tra xem tên nhóm có rỗng không
    if (groupNameController.text.isEmpty) {
      showSnackBar(context, 'Vui lòng nhập tên nhóm');
      return;
    }

    // kiểm tra xem tên nhóm có ít hơn 3 ký tự không
    if (groupNameController.text.length < 3) {
      showSnackBar(context, 'Vui lòng nhập tên nhóm từ 3 ký tự trở lên');
      return;
    }

    // check if the group description is empty
    // if (groupDescriptionController.text.isEmpty) {
    //   showSnackBar(context, 'Vui lòng nhập mô tả nhóm');
    //   return;
    // }

    // tạo một đối tượng GroupModel
    GroupModel groupModel = GroupModel(
      creatorUID: uid,
      groupName: groupNameController.text,
      // groupDescription: groupDescriptionController.text,
      groupDescription: '',
      groupImage: '',
      groupID: '',
      lastMessage: '',
      senderUID: '',
      messageType: MessageEnum.text,
      messageID: '',
      timeSent: DateTime.now(),
      createdAt: DateTime.now(),
      editSettings: true,
      membersUIDs: [],
      adminsUIDs: [],
    );

    // tạo nhóm xử lý thanh công/thất bại
    // groupProvider.createGroup(
    //   newGroupModel: groupModel,
    //   fileImage: finalFileImage,
    //   onSuccess: () {
    //     showSnackBar(context, 'Tạo nhóm thành công');
    //     Navigator.pop(context);
    //   },
    //   onFail: (error) {
    //     showSnackBar(context, error);
    //   },
    // );

    // tạo nhóm
    groupProvider.createGroup(
      newGroupModel: groupModel,
      fileImage: finalFileImage,
      onSuccess: (String groupID) {
        // Nhận groupID từ callback
        showSnackBar(context, 'Tạo nhóm thành công');

        // Chuyển hướng tới màn hình trò chuyện nhóm vừa tạo
        // Navigator.pushReplacementNamed thay màn hình hiện tại bằng màn hình đích (màn hình nhóm), xóa màn hình hiện tại khỏi ngăn xếp của Navigator.
        Navigator.pushReplacementNamed(
          context,
          Constants
              .chatScreen, // route (Đường dẫn) tới màn hình trò chuyện nhóm
          arguments: {
            Constants.contactUID: groupID,
            Constants.contactName: groupModel.groupName,
            Constants.contactImage: groupModel.groupImage,
            Constants.groupID: groupID,
          },
        );
      },
      onFail: (error) {
        showSnackBar(context, error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tạo nhóm'),
        // centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              child: context.watch<GroupProvider>().isSloading
                  ? const CircularProgressIndicator()
                  : IconButton(
                      onPressed: () {
                        // create group
                        createGroup();
                      },
                      icon: const Icon(Icons.check)),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 10.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DisplayUserImage(
                  finalFileImage: finalFileImage,
                  radius: 60,
                  onPressed: () {
                    showBottomSheet();
                  },
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 10),

            // texField for group name
            TextField(
              controller: groupNameController,
              maxLength: 25,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Tên nhóm',
                label: Text('Tên nhóm'),
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            // textField for group description
            // TextField(
            //   controller: groupDescriptionController,
            //   maxLength: 100,
            //   textInputAction: TextInputAction.done,
            //   decoration: const InputDecoration(
            //     hintText: 'Mô tả',
            //     label: Text('Mô tả'),
            //     counterText: '',
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            // const SizedBox(height: 10),
            const Card(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Chọn thành viên',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // cuppertino search bar
            CupertinoSearchTextField(
              placeholder: 'Tìm kiếm',
              onChanged: (value) {},
            ),

            const SizedBox(height: 10),

            const Expanded(
              child: FriendsList(
                viewType: FriendViewType.groupView,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
