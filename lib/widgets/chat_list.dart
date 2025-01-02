import 'package:chat_app_flutter/models/message_model.dart';
import 'package:chat_app_flutter/models/message_reply_model.dart';
import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/providers/chat_provider.dart';
import 'package:chat_app_flutter/utilities/global_methods.dart';
import 'package:chat_app_flutter/widgets/contact_message_widget.dart';
import 'package:chat_app_flutter/widgets/my_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:provider/provider.dart';

class ChatList extends StatefulWidget {
  const ChatList({
    super.key,
    required this.contactUID,
    required this.groupID,
  });

  final String contactUID;
  final String groupID;

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  // scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // uid của người dùng hiện tại
    final uid = context.read<AuthenticationProvider>().userModel!.uid;

    return GestureDetector(
      onVerticalDragDown: (_) {
        FocusScope.of(context).unfocus();
      },
      child: StreamBuilder<List<MessageModel>>(
        stream: context.read<ChatProvider>().getMessagesStream(
              userID: uid,
              contactUID: widget.contactUID,
              isGroup: widget.groupID,
            ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Đã có lỗi xảy ra'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Bắt đầu cuộc trò chuyện',
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            );
          }

          // tự động cuộn xuống cuối tin nhắn mới
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.minScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          });

          if (snapshot.hasData) {
            final messagesList = snapshot.data!;
            return GroupedListView<dynamic, DateTime>(
                // reverse: true đảo ngược thứ tự hiển thị các phần tử trong danh sách
                reverse: true,
                controller: _scrollController,
                elements: messagesList,
                groupBy: (element) {
                  return DateTime(
                    element.timeSent!.year,
                    element.timeSent!.month,
                    element.timeSent!.day,
                  );
                },
                groupHeaderBuilder: (dynamic groupByValue) =>
                    buildDateTime(groupByValue),
                itemBuilder: (context, dynamic element) {
                  // set message as seen
                  if (!element.isSeen && element.senderUID != uid) {
                    context.read<ChatProvider>().setMessageAsSeen(
                          userID: uid,
                          contactUID: widget.contactUID,
                          messageID: element.messageID,
                          groupID: widget.groupID,
                        );
                  }

                  // kiểm tra xem người dùng đã gửi tin nhắn cuối cùng (last message) hay chưa
                  final isMe = element.senderUID == uid;
                  return isMe
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: MyMessageWidget(
                            message: element,
                            onLeftSwipe: () {
                              // set the message reply to true
                              final messageReply = MessageReplyModel(
                                message: element.message,
                                senderUID: element.senderUID,
                                senderName: element.senderName,
                                senderImage: element.senderImage,
                                messageType: element.messageType,
                                isMe: isMe,
                              );

                              context
                                  .read<ChatProvider>()
                                  .setMessageReplyModel(messageReply);
                            },
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: ContactMessageWidget(
                            message: element,
                            onRightSwipe: () {
                              // set the message reply to true
                              final messageReply = MessageReplyModel(
                                message: element.message,
                                senderUID: element.senderUID,
                                senderName: element.senderName,
                                senderImage: element.senderImage,
                                messageType: element.messageType,
                                isMe: isMe,
                              );

                              context
                                  .read<ChatProvider>()
                                  .setMessageReplyModel(messageReply);
                            },
                          ),
                        );
                },
                groupComparator: (value1, value2) => value2.compareTo(value1),
                itemComparator: (item1, item2) {
                  var firstItem = item1.timeSent;
                  var secondItem = item2.timeSent;
                  return secondItem!.compareTo(firstItem!);
                },
                useStickyGroupSeparators: true, // optional
                floatingHeader: true, // optional
                order: GroupedListOrder.ASC // optional
                );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
