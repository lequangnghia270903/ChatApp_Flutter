import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/widgets/app_bar_back_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;

  //get the saved theme mode
  void getThemeMode() async {
    final savedThemeMode = await AdaptiveTheme.getThemeMode();

    if (savedThemeMode == AdaptiveThemeMode.dark) {
      setState(() {
        isDarkMode = true;
      });
    } else {
      setState(() {
        isDarkMode = false;
      });
    }
  }

  @override
  void initState() {
    getThemeMode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    // get thẻ uid from arguments
    final uid = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(onPressed: () {
          Navigator.pop(context);
        }),
        // centerTitle: true,
        title: const Text('Cài đặt'),
        actions: [
          currentUser.uid == uid
              ?
              // logout button
              IconButton(
                  onPressed: () async {
                    // createe a dialog to confirm logout
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Bạn có muốn đăng xuất không?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () async {
                              // logout
                              await context
                                  .read<AuthenticationProvider>()
                                  .logout()
                                  .whenComplete(() {
                                Navigator.pop(context);
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  Constants.loginScreen,
                                  (route) => false,
                                );
                              });
                            },
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout),
                )
              : const SizedBox(),
        ],
      ),
      body: Center(
        child: Card(
            child: SwitchListTile(
          title: Text('Chế độ Sáng/Tối'),
          secondary: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            child: Icon(
              isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
              color: isDarkMode ? Colors.black : Colors.white,
            ),
          ),
          value: isDarkMode,
          onChanged: (value) {
            setState(() {
              isDarkMode = value;
            });

            if (value) {
              AdaptiveTheme.of(context).setDark();
            } else {
              AdaptiveTheme.of(context).setLight();
            }
          },
        )),
      ),
    );
  }
}
