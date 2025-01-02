import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/widgets/friends_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lời mời kết bạn'),
      ),
      body: Column(
        children: [
          // cupertino search bar
          CupertinoSearchTextField(
            placeholder: 'Tìm kiếm',
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              print(value);
            },
          ),

          const Expanded(
              child: FriendsList(
            viewType: FriendViewType.friendRequests,
          )),
        ],
      ),
    );
  }
}
