import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/models/last_message_model.dart';
import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/providers/chat_provider.dart';
import 'package:chat_app_flutter/providers/connectivity_provider.dart';
import 'package:chat_app_flutter/utilities/global_methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyChatsScreen extends StatefulWidget {
  const MyChatsScreen({super.key});

  @override
  State<MyChatsScreen> createState() => _MyChatsScreenState();
}

class _MyChatsScreenState extends State<MyChatsScreen> {
  late bool isConnected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isConnected = context.watch<ConnectivityProvider>().isConnected;
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Hiển thị thông báo kết nối mạng
            if (!isConnected)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: const Text(
                  'Không có kết nối Internet',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            // cupertino search bar
            CupertinoSearchTextField(
              placeholder: 'Tìm kiếm',
              onChanged: (value) {
                print(value);
              },
            ),

            Expanded(
              child: StreamBuilder<List<LastMessageModel>>(
                stream: context.read<ChatProvider>().getChatsListStream(uid),
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
                  if (snapshot.hasData) {
                    final chatsList = snapshot.data!;
                    return ListView.builder(
                      itemCount: chatsList.length,
                      itemBuilder: (context, index) {
                        final chat = chatsList[index];
                        final dateTime =
                            formatDate(chat.timeSent, [HH, ':', nn]);
                        // check if we send the last message
                        final isMe = chat.senderUID == uid;
                        // display the last message correctly
                        final lastMessage =
                            isMe ? 'Bạn: ${chat.message}' : chat.message;
                        return ListTile(
                          leading: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(chat
                                    .contactUID) // ID của người dùng liên hệ
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final userData = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                final isOnline = userData['isOnline'] ?? false;

                                bool isUserOnline = isConnected && isOnline;
                                // Nếu không có kết nối mạng, ẩn dấu chấm xanh
                                return Stack(
                                  children: [
                                    // Avatar
                                    userImageWidget(
                                      imageUrl: chat.contactImage,
                                      radius: 40,
                                      onTap: () {},
                                    ),
                                    // Dấu chấm xanh
                                    if (isUserOnline)
                                      Positioned(
                                        right: 12,
                                        bottom: 0,
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  Theme.of(context).cardColor,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              } else {
                                return userImageWidget(
                                  imageUrl: chat.contactImage,
                                  radius: 40,
                                  onTap: () {},
                                );
                              }
                            },
                          ),
                          contentPadding: EdgeInsets.zero,
                          title: Text(chat.contactName),
                          subtitle: messageToShow(
                            type: chat.messageType,
                            message: lastMessage,
                          ),
                          trailing: Text(dateTime),
                          onTap: () {
                            // chuyển đến màn hình chat
                            Navigator.pushNamed(
                              context,
                              Constants.chatScreen,
                              arguments: {
                                Constants.contactUID: chat.contactUID,
                                Constants.contactName: chat.contactName,
                                Constants.contactImage: chat.contactImage,
                                Constants.groupID: '',
                              },
                            );
                          },
                        );
                      },
                    );
                  }
                  return const Center(
                    child: Text('Không có tin nhắn nào'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
