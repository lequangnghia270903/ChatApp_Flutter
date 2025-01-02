import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/utilities/global_methods.dart';
import 'package:chat_app_flutter/widgets/app_bar_back_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    // get user data from arguments
    final uid = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(onPressed: () {
          Navigator.pop(context);
        }),
        // centerTitle: true,
        title: const Text('Trang cá nhân'),
        actions: [
          currentUser.uid == uid
              ?
              // logout button
              IconButton(
                  onPressed: () async {
                    // điều hướng đến màn hình yêu cầu bạn kết nối
                    await Navigator.pushNamed(
                      context,
                      Constants.settingScreen,
                      arguments: uid,
                    );
                  },
                  icon: const Icon(Icons.settings),
                )
              : const SizedBox(),
        ],
      ),
      body: StreamBuilder(
        stream:
            context.read<AuthenticationProvider>().getUserStream(userID: uid),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Đã có lỗi xảy ra'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userModel =
              UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 20.0,
            ),
            child: Column(
              children: [
                Center(
                  child: userImageWidget(
                    imageUrl: userModel.image,
                    radius: 60,
                    onTap: () {
                      // na
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  userModel.name,
                  style: GoogleFonts.openSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                currentUser.uid == userModel.uid
                    ? Text(
                        userModel.phoneNumber,
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : const SizedBox.shrink(),
                const SizedBox(height: 10),
                buildFriendRequestButton(
                  currentUser: currentUser,
                  userModel: userModel,
                ),
                const SizedBox(height: 10),
                buildFriendButton(
                  currentUser: currentUser,
                  userModel: userModel,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 40,
                      width: 40,
                      child: Divider(
                        color: Colors.grey,
                        thickness: 1,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Giới thiệu',
                      style: GoogleFonts.openSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const SizedBox(
                      height: 40,
                      width: 40,
                      child: Divider(
                        color: Colors.grey,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                Text(
                  userModel.aboutMe,
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // friend request button
  Widget buildFriendRequestButton({
    required UserModel currentUser,
    required UserModel userModel,
  }) {
    if (currentUser.uid == userModel.uid &&
        userModel.friendRequestsUIDs.isNotEmpty) {
      return buildElevatedButton(
        onPressed: () {
          // navigate to friend request screen
          Navigator.pushNamed(
            context,
            Constants.friendRequestScreen,
          );
        },
        lable: 'Xem lời mời kết bạn',
        width: MediaQuery.of(context).size.width * 0.7,
        backgroundColor: Theme.of(context).cardColor,
        textColor: Theme.of(context).colorScheme.primary,
      );
    } else {
      // not in our profile
      return const SizedBox.shrink();
    }
  }

  // friends button
  Widget buildFriendButton({
    required UserModel currentUser,
    required UserModel userModel,
  }) {
    if (currentUser.uid == userModel.uid && userModel.friendsUIDs.isNotEmpty) {
      return buildElevatedButton(
        onPressed: () {
          // điều hướng đến màn hình yêu cầu kết bạn
          Navigator.pushNamed(
            context,
            Constants.friendScreen,
          );
        },
        lable: 'Xem bạn bè',
        width: MediaQuery.of(context).size.width * 0.7,
        backgroundColor: Theme.of(context).cardColor,
        textColor: Theme.of(context).colorScheme.primary,
      );
    } else {
      if (currentUser.uid != userModel.uid) {
        // hiển thị nút hủy yêu cầu kết bạn nếu người dùng đã gửi yêu cầu kết bạn
        // nếu không thì hiển thị nút gửi yêu cầu kết bạn
        if (userModel.friendRequestsUIDs.contains(currentUser.uid)) {
          // hiển thị nút gửi yêu cầu kết bạn
          return buildElevatedButton(
            onPressed: () async {
              await context
                  .read<AuthenticationProvider>()
                  .cancelFriendRequest(friendID: userModel.uid)
                  .whenComplete(() {
                showSnackBar(context, 'Đã hủy lời mời kết bạn');
              });
            },
            lable: 'Hủy lời mời kết bạn',
            width: MediaQuery.of(context).size.width * 0.7,
            backgroundColor: Theme.of(context).cardColor,
            textColor: Theme.of(context).colorScheme.primary,
          );
        } else if (userModel.sentFriendRequestsUIDs.contains(currentUser.uid)) {
          return buildElevatedButton(
            onPressed: () async {
              await context
                  .read<AuthenticationProvider>()
                  .acceptFriendRequest(friendID: userModel.uid)
                  .whenComplete(() {
                showSnackBar(
                    context, 'Bạn đã trở thành bạn bè với ${userModel.name}');
              });
            },
            lable: 'Chấp nhận lời mời kết bạn',
            width: MediaQuery.of(context).size.width * 0.7,
            backgroundColor: Theme.of(context).cardColor,
            textColor: Theme.of(context).colorScheme.primary,
          );
        } else if (userModel.friendsUIDs.contains(currentUser.uid)) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildElevatedButton(
                onPressed: () async {
                  // hiển thị hộp thoại hủy kết bạn để hỏi người dùng xem họ có chắc chắn hủy kết bạn không
                  // tạo hộp thoại để xác nhận hủy kết bạn
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'Bạn có muốn hủy kết bạn với ${userModel.name} không?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Không'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            // xóa bạn bè
                            await context
                                .read<AuthenticationProvider>()
                                .removeFriend(friendID: userModel.uid)
                                .whenComplete(() {
                              showSnackBar(context, 'Đã hủy kết bạn');
                            });
                          },
                          child: const Text('Có'),
                        ),
                      ],
                    ),
                  );
                },
                lable: 'Hủy kết bạn',
                width: MediaQuery.of(context).size.width * 0.4,
                backgroundColor: Theme.of(context).cardColor,
                textColor: Colors.red,
              ),
              buildElevatedButton(
                onPressed: () async {
                  // navigate to chat screen
                  // navigate to chat screen with the folowing argument
                  // 1. friend uid 2. friend name 3. friend image 4. group with an empty string
                  Navigator.pushNamed(context, Constants.chatScreen,
                      arguments: {
                        Constants.contactUID: userModel.uid,
                        Constants.contactName: userModel.name,
                        Constants.contactImage: userModel.image,
                        Constants.groupID: '',
                      });
                },
                lable: 'Nhắn tin',
                width: MediaQuery.of(context).size.width * 0.4,
                backgroundColor: Theme.of(context).cardColor,
                textColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          );
        } else {
          return buildElevatedButton(
            onPressed: () async {
              await context
                  .read<AuthenticationProvider>()
                  .sendFriendRequest(friendID: userModel.uid)
                  .whenComplete(() {
                showSnackBar(context, 'Đã gửi lời mời kết bạn');
              });
            },
            lable: 'Gửi lời mời kết bạn',
            width: MediaQuery.of(context).size.width * 0.7,
            backgroundColor: Theme.of(context).cardColor,
            textColor: Theme.of(context).colorScheme.primary,
          );
        }
      } else {
        return const SizedBox.shrink();
      }
    }
  }

  Widget buildElevatedButton({
    required VoidCallback onPressed,
    required String lable,
    required double width,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 5,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          lable.toUpperCase(),
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
