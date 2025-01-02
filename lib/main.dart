import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:chat_app_flutter/authentication/landing_screen.dart';
import 'package:chat_app_flutter/authentication/login_screen.dart';
import 'package:chat_app_flutter/authentication/otp_screen.dart';
import 'package:chat_app_flutter/authentication/user_information_screen.dart';
import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/firebase_options.dart';
import 'package:chat_app_flutter/main_screen/chat_screen.dart';
import 'package:chat_app_flutter/main_screen/friend_requests_screen.dart';
import 'package:chat_app_flutter/main_screen/friends_screen.dart';
import 'package:chat_app_flutter/main_screen/home_screen.dart';
import 'package:chat_app_flutter/main_screen/profile_screen.dart';
import 'package:chat_app_flutter/main_screen/settings_screen.dart';
import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/providers/chat_provider.dart';
import 'package:chat_app_flutter/providers/connectivity_provider.dart';
import 'package:chat_app_flutter/providers/group_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
      ],
      child: MyApp(savedThemeMode: savedThemeMode),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.savedThemeMode});

  final AdaptiveThemeMode? savedThemeMode;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
      ),
      dark: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
      ),
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: theme,
        darkTheme: darkTheme,
        // home: const LoginScreen(),
        initialRoute: Constants.landingScreen,
        routes: {
          Constants.landingScreen: (context) => const LandingScreen(),
          Constants.loginScreen: (context) => const LoginScreen(),
          Constants.otpScreen: (context) => const OTPScreen(),
          Constants.userInformationScreen: (context) =>
              const UserInformationScreen(),
          Constants.homeScreen: (context) => const HomeScreen(),
          Constants.profileScreen: (context) => const ProfileScreen(),
          Constants.settingScreen: (context) => const SettingsScreen(),
          Constants.friendScreen: (context) => const FriendsScreen(),
          Constants.friendRequestScreen: (context) =>
              const FriendRequestsScreen(),
          Constants.chatScreen: (context) => const ChatScreen(),
        },
      ),
    );
  }
}
