import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/main_screen/create_group_screen.dart';
import 'package:chat_app_flutter/main_screen/groups_screen.dart';
import 'package:chat_app_flutter/main_screen/my_chats_screen.dart';
import 'package:chat_app_flutter/main_screen/people_screen.dart';
import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/providers/group_provider.dart';
import 'package:chat_app_flutter/utilities/global_methods.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final PageController pageController = PageController(initialPage: 0);
  int currentIndex = 0;

  final List<Widget> screens = const [
    MyChatsScreen(),
    GroupsScreen(),
    PeopleScreen(),
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        // user comes back to the app
        // check if the user has an active network connection
        var connectivityResult = await Connectivity().checkConnectivity();
        bool isConnected = connectivityResult != ConnectivityResult.none;
        // update user status to online only if there is a network connection
        if (isConnected) {
          context.read<AuthenticationProvider>().updateUserStatus(
                value: true,
              );
        } else {
          context.read<AuthenticationProvider>().updateUserStatus(
                value: false, // Or keep it offline if desired
              );
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // app is in inactive, paused, detached, hidden state
        // update user status to offline
        context.read<AuthenticationProvider>().updateUserStatus(
              value: false,
            );
      default:
        // handle other states
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthenticationProvider>();

    return Scaffold(
        appBar: AppBar(
          title: const Text('Chat App'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: userImageWidget(
                imageUrl: authProvider.userModel!.image,
                radius: 20,
                onTap: () {
                  // navigate to profile screen
                  Navigator.pushNamed(
                    context,
                    Constants.profileScreen,
                    arguments: authProvider.userModel!.uid,
                  );
                },
              ),
            ),
          ],
        ),
        body: PageView(
          controller: pageController,
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          children: screens,
        ),
        floatingActionButton: currentIndex == 1
            ? FloatingActionButton(
                onPressed: () {
                  context
                      .read<GroupProvider>()
                      .clearGroupMembersList()
                      .whenComplete(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateGroupScreen(),
                      ),
                    );
                  });
                },
                backgroundColor: Colors.blueAccent,
                child: const Icon(
                  CupertinoIcons.add,
                  color: Colors.white,
                ),
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Đoạn chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Nhóm',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.language),
              label: 'Mọi người',
            ),
          ],
          currentIndex: currentIndex,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            // Tạo hiệu ứng cho Chế độ xem trang theo chỉ mục trang được chỉ định.
            pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
            if (index == 1) {
              setState(() {
                currentIndex = index;
              });
            }
          },
        ));
  }
}
