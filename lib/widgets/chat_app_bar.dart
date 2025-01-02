import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/providers/connectivity_provider.dart';
import 'package:chat_app_flutter/utilities/global_methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatAppBar extends StatefulWidget {
  const ChatAppBar({super.key, required this.contactUID});

  final String contactUID;

  @override
  State<ChatAppBar> createState() => _ChatAppBarState();
}

class _ChatAppBarState extends State<ChatAppBar> {
  late bool isConnected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isConnected = context.watch<ConnectivityProvider>().isConnected;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context
          .read<AuthenticationProvider>()
          .getUserStream(userID: widget.contactUID),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Đã có lỗi xảy ra'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userModel =
            UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

        DateTime lastSeen =
            DateTime.fromMillisecondsSinceEpoch(int.parse(userModel.lastSeen));

        // Kết hợp isConnected và userModel.isOnline để xác định trạng thái
        bool isUserOnline = isConnected && userModel.isOnline;

        return Row(
          children: [
            Stack(
              children: [
                // Avatar của người dùng
                userImageWidget(
                  imageUrl: userModel.image,
                  radius: 20,
                  onTap: () {
                    // navigate to this friend's profile with uid as argument
                    Navigator.pushNamed(
                      context,
                      Constants.profileScreen,
                      arguments: userModel.uid,
                    );
                  },
                ),
                // Dấu chấm xanh
                if (isUserOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context)
                              .cardColor, // Đường viền để tách biệt
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userModel.name,
                  style: GoogleFonts.openSans(fontSize: 16),
                ),
                Text(
                  !isConnected
                      ? 'Đang đợi mạng'
                      : (isUserOnline
                          ? 'Đang hoạt động'
                          : (lastSeen.isBefore(DateTime.now()
                                  .subtract(const Duration(minutes: 1)))
                              ? 'Hoạt động ${timeago.format(lastSeen)}'
                              : 'Vừa mới hoạt động')),
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    color: !isConnected
                        ? Colors.red // Màu sắc cho trạng thái mất mạng
                        : (isUserOnline
                            ? Colors.green
                            : const Color.fromARGB(255, 119, 104, 104)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
