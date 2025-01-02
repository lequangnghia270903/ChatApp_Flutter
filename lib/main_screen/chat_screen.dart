import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/widgets/bottom_chat_field.dart';
import 'package:chat_app_flutter/widgets/chat_app_bar.dart';
import 'package:chat_app_flutter/widgets/chat_list.dart';
import 'package:chat_app_flutter/widgets/group_chat_app_bart.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    // lấy các đối số được truyền từ màn hình trước
    final arguments = ModalRoute.of(context)!.settings.arguments as Map;
    // lấy contactUID từ arguments
    final contactUID = arguments[Constants.contactUID];
    // lấy contactName từ arguments
    final contactName = arguments[Constants.contactName];
    // lấy contactImage từ arguments
    final contactImage = arguments[Constants.contactImage];
    // lấy groupID từ arguments
    final groupID = arguments[Constants.groupID];
    // kiểm tra groupID có trống không - nếu trống thì đó là cuộc trò chuyện với một người bạn, nếu không thì đó là cuộc trò chuyện
    final isGroupChat = groupID.isNotEmpty ? true : false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: // get appBar color from theme
            Theme.of(context).appBarTheme.backgroundColor,
        title: isGroupChat
            ? GroupChatAppBar(groupID: groupID)
            : ChatAppBar(contactUID: contactUID),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ChatList(
                contactUID: contactUID,
                groupID: groupID,
              ),
            ),
            BottomChatField(
              contactUID: contactUID,
              contactName: contactName,
              contactImage: contactImage,
              groupID: groupID,
            )
          ],
        ),
      ),
    );
  }
}
