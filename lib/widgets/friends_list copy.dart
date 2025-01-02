// import 'package:chat_app_flutter/constants.dart';
// import 'package:chat_app_flutter/models/user_model.dart';
// import 'package:chat_app_flutter/providers/authentication_provider.dart';
// import 'package:chat_app_flutter/utilities/global_methods.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class FriendsList extends StatelessWidget {
//   const FriendsList({
//     super.key,
//     required this.viewType,
//   });

//   final FriendViewType viewType;

//   @override
//   Widget build(BuildContext context) {
//     final uid = context.read<AuthenticationProvider>().userModel!.uid;

//     final future = viewType == FriendViewType.friends
//         ? context.read<AuthenticationProvider>().getFriendsList(uid)
//         : viewType == FriendViewType.friendRequests
//             ? context.read<AuthenticationProvider>().getFriendRequestsList(uid)
//             : context.read<AuthenticationProvider>().getFriendsList(uid);

//     return FutureBuilder<List<UserModel>>(
//       future: future,
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return const Center(child: Text('Đã có lỗi xảy ra'));
//         }

//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(child: Text('Không có bạn bè'));
//         }

//         if (snapshot.connectionState == ConnectionState.done) {
//           return ListView.builder(
//             itemCount: snapshot.data!.length,
//             itemBuilder: (context, index) {
//               final data = snapshot.data![index];
//               return ListTile(
//                 contentPadding: const EdgeInsets.only(
//                   left: -10,
//                 ),
//                 leading: userImageWidget(
//                   imageUrl: snapshot.data![index].image,
//                   radius: 40,
//                   onTap: () {
//                     // navigate to this firends profile with uid as argument
//                     Navigator.pushNamed(
//                       context,
//                       Constants.profileScreen,
//                       arguments: data.uid,
//                     );
//                   },
//                 ),
//                 title: Text(data.name),
//                 // subtitle: Text(data.aboutMe),
//                 trailing: ElevatedButton(
//                   onPressed: () async {
//                     if (viewType == FriendViewType.friends) {
//                       // navigate to chat screen with the folowing argument
//                       // 1. friend uid 2. friend name 3. friend image 4. group with an empty string
//                       Navigator.pushNamed(context, Constants.chatScreen,
//                           arguments: {
//                             Constants.contactUID: data.uid,
//                             Constants.contactName: data.name,
//                             Constants.contactImage: data.image,
//                             Constants.groupID: '',
//                           });
//                     } else if (viewType == FriendViewType.friendRequests) {
//                       // accept friend request
//                       await context
//                           .read<AuthenticationProvider>()
//                           .acceptFriendRequest(friendID: data.uid)
//                           .whenComplete(() {
//                         showSnackBar(context,
//                             'Bạn đã trở thành bạn bè với ${data.name}');
//                       });
//                     } else {
//                       // check the check box
//                     }
//                   },
//                   child: viewType == FriendViewType.friends
//                       ? const Text('Nhắn tin')
//                       : const Text('Chấp nhận'),
//                 ),
//               );
//             },
//           );
//         }

//         return const Center(child: CircularProgressIndicator());
//       },
//     );
//   }
// }
