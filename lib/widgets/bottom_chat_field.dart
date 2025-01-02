import 'dart:io';

import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/providers/chat_provider.dart';
import 'package:chat_app_flutter/utilities/global_methods.dart';
import 'package:chat_app_flutter/widgets/message_reply_preview.dart';
import 'package:chat_app_flutter/widgets/speech_to_text_dialog.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

class BottomChatField extends StatefulWidget {
  const BottomChatField({
    super.key,
    required this.contactUID,
    required this.contactName,
    required this.contactImage,
    required this.groupID,
  });

  final String contactUID;
  final String contactName;
  final String contactImage;
  final String groupID;

  @override
  State<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends State<BottomChatField> {
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  File? finalFileImage;
  String filePath = '';

  bool isTextFieldNotEmpty = false; // Trạng thái kiểm tra TextField

  @override
  void initState() {
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
    super.initState();

    // Lắng nghe thay đổi nội dung trong TextField
    _textEditingController.addListener(() {
      setState(() {
        isTextFieldNotEmpty = _textEditingController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void selectImage(bool fromCamera) async {
    finalFileImage = await pickImage(
      fromCamera: fromCamera,
      onFail: (String message) {
        showSnackBar(
          context,
          message,
        );
      },
    );

    // crop the image
    await cropImage(finalFileImage?.path);

    popContext();
  }

  // select a video file from gallery
  void selectVideo() async {
    File? fileVideo = await pickVideo(
      onFail: (String message) {
        showSnackBar(context, message);
      },
    );
    popContext();
    if (fileVideo != null) {
      filePath = fileVideo.path;
      // send video message to firebase
      sendFileMessage(
        messageType: MessageEnum.video,
      );
    }
  }

  popContext() {
    Navigator.pop(context);
  }

  Future<void> cropImage(croppedFilePath) async {
    if (croppedFilePath != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: croppedFilePath,
        maxWidth: 800,
        maxHeight: 800,
        compressQuality: 90,
      );
      if (croppedFile != null) {
        filePath = croppedFile.path;
        // send image message to firebase
        sendFileMessage(
          messageType: MessageEnum.image,
        );
      }
    }
  }

  // send image message to firebase
  void sendFileMessage({
    required MessageEnum messageType,
  }) {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final chatProvider = context.read<ChatProvider>();

    chatProvider.sendFileMessage(
      sender: currentUser,
      contactUID: widget.contactUID,
      contactName: widget.contactName,
      contactImage: widget.contactImage,
      file: File(filePath),
      messageType: messageType,
      groupID: widget.groupID,
      onSuccess: () {
        _textEditingController.clear();
        _focusNode.unfocus();
      },
      onError: (error) {
        showSnackBar(context, error);
      },
    );
  }

  // send text message to firebase
  void sendTextMessage() {
    // Kiểm tra nếu TextFormField rỗng
    if (_textEditingController.text.trim().isEmpty) {
      return; // Không làm gì cả nếu nội dung tin nhắn rỗng
    }

    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final chatProvider = context.read<ChatProvider>();

    chatProvider.sendTextMessage(
      sender: currentUser,
      contactUID: widget.contactUID,
      contactName: widget.contactName,
      contactImage: widget.contactImage,
      message: _textEditingController.text,
      messageType: MessageEnum.text,
      groupID: widget.groupID,
      onSuccess: () {
        _textEditingController.clear();
        _focusNode.unfocus();
      },
      onError: (error) {
        showSnackBar(context, error);
      },
    );
  }

  void speechToText() {
    SpeechDialog.show(context, _textEditingController);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messageReply = chatProvider.messageReplyModel;
        final isMessageReply = messageReply != null;
        return Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Theme.of(context).cardColor,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
              )),
          child: Column(
            children: [
              isMessageReply
                  ? const MessageReplyPreview()
                  : const SizedBox.shrink(),
              Row(
                children: [
                  chatProvider.isLoading
                      ? const CircularProgressIndicator()
                      : IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return SizedBox(
                                  height: 200,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        // select image from camera
                                        ListTile(
                                          leading: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.blue,
                                          ),
                                          title: const Text('Camera'),
                                          onTap: () {
                                            selectImage(true);
                                          },
                                        ),
                                        // select image from gallery
                                        ListTile(
                                          leading: const Icon(
                                            Icons.image,
                                            color: Colors.blue,
                                          ),
                                          title: const Text('Thư viện'),
                                          onTap: () {
                                            selectImage(false);
                                          },
                                        ),
                                        // select a video file from device
                                        ListTile(
                                          leading: const Icon(
                                            Icons.video_library,
                                            color: Colors.blue,
                                          ),
                                          title: const Text('Video'),
                                          onTap: selectVideo,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.attachment,
                            color: Colors.blue,
                          ),
                        ),
                  Expanded(
                    child: TextFormField(
                      controller: _textEditingController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration.collapsed(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(30),
                          ),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Nhắn tin',
                      ),
                    ),
                  ),
                  chatProvider.isLoading
                      ? const CircularProgressIndicator()
                      : GestureDetector(
                          onTap: isTextFieldNotEmpty
                              ? sendTextMessage
                              : speechToText,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.blue,
                            ),
                            margin: const EdgeInsets.all(5),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                isTextFieldNotEmpty ? Icons.send : Icons.mic,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
