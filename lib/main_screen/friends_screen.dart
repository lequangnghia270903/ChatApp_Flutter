import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/widgets/app_bar_back_button.dart';
import 'package:chat_app_flutter/widgets/friends_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Bạn bè'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
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
              viewType: FriendViewType.friends,
            )),
          ],
        ),
      ),
    );
  }
}
