import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/widgets/friend_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FriendsList extends StatelessWidget {
  const FriendsList({
    super.key,
    required this.viewType,
    this.groupId = '',
    this.groupMembersUIDs = const [],
  });

  final FriendViewType viewType;
  final String groupId;
  final List<String> groupMembersUIDs;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;

    final future = viewType == FriendViewType.friends
        ? context.read<AuthenticationProvider>().getFriendsList(
              uid,
              groupMembersUIDs,
            )
        : viewType == FriendViewType.friendRequests
            ? context.read<AuthenticationProvider>().getFriendRequestsList(
                  uid: uid,
                  groupId: groupId,
                )
            : context.read<AuthenticationProvider>().getFriendsList(
                  uid,
                  groupMembersUIDs,
                );

    return FutureBuilder<List<UserModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Đã có lỗi xảy ra"));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Không có bạn bè"));
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final data = snapshot.data![index];
              return FriendWidget(
                friend: data,
                viewType: viewType,
                groupId: groupId,
              );
            },
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
