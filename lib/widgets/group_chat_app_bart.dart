import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/models/group_model.dart';
import 'package:chat_app_flutter/providers/group_provider.dart';
import 'package:chat_app_flutter/utilities/global_methods.dart';
import 'package:chat_app_flutter/widgets/group_member.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GroupChatAppBar extends StatefulWidget {
  const GroupChatAppBar({super.key, required this.groupID});

  final String groupID;

  @override
  State<GroupChatAppBar> createState() => _GroupChatAppBarState();
}

class _GroupChatAppBarState extends State<GroupChatAppBar> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream:
          context.read<GroupProvider>().groupStream(groupID: widget.groupID),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Đã có lỗi xảy ra'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groupModel =
            GroupModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

        return GestureDetector(
          onTap: () {
            // navigate to group information screen
            context
                .read<GroupProvider>()
                .updateGroupMembersList()
                .whenComplete(() {
              Navigator.pushNamed(context, Constants.groupInformationScreen);
            });
          },
          child: Row(
            children: [
              userImageWidget(
                imageUrl: groupModel.groupImage,
                radius: 20,
                onTap: () {
                  // navigate to group settings screen
                },
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(groupModel.groupName),
                  GroupMembers(membersUIDs: groupModel.membersUIDs),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
