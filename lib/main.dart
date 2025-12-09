import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'my_themes.dart';
import 'register_screen.dart';
import 'splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';l

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child : MaterialApp(
       title: 'Demo',
       themeMode: ThemeMode.system,
       theme: MyThemes.lightTheme,
       darkTheme: MyThemes.darkTheme,
       home: SplashScreen(),
       debugShowCheckedModeBanner: false,
      ),
    );
  }
}
