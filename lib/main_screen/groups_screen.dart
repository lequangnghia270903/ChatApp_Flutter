import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/models/group_model.dart';
import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/providers/group_provider.dart';
import 'package:chat_app_flutter/widgets/chat_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // appBar: AppBar(
        //   title: const TabBar(
        //     indicatorSize: TabBarIndicatorSize.label,
        //     tabs: [
        //       Tab(
        //         text: 'Nhóm',
        //       ),
        //     ],
        //   ),
        // ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CupertinoSearchTextField(
                  placeholder: 'Tìm kiếm',
                  onChanged: (value) {},
                ),
              ),

              // stream builder for private groups
              StreamBuilder<List<GroupModel>>(
                stream: context.read<GroupProvider>().GroupsStream(userId: uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Đã có lỗi xảy ra'),
                    );
                  }
                  if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Không có nhóm nào'),
                    );
                  }

                  // Sắp xếp danh sách nhóm dựa trên datetime
                  final sortedGroups = snapshot.data!
                    ..sort((a, b) => b.timeSent.compareTo(a.timeSent));

                  // Trả về danh sách đã sắp xếp
                  return Expanded(
                    child: ListView.builder(
                      itemCount: sortedGroups.length,
                      itemBuilder: (context, index) {
                        final groupModel = sortedGroups[index];
                        return ChatWidget(
                            group: groupModel,
                            isGroup: true,
                            onTap: () {
                              context
                                  .read<GroupProvider>()
                                  .setGroupModel(groupModel: groupModel)
                                  .whenComplete(() {
                                Navigator.pushNamed(
                                  context,
                                  Constants.chatScreen,
                                  arguments: {
                                    Constants.contactUID: groupModel.groupID,
                                    Constants.contactName: groupModel.groupName,
                                    Constants.contactImage:
                                        groupModel.groupImage,
                                    Constants.groupID: groupModel.groupID,
                                  },
                                );
                              });
                            });
                      },
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
