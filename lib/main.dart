import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'my_themes.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo',
      themeMode: ThemeMode.system,
      theme: MyThemes.lightTheme,
      darkTheme: MyThemes.darkTheme,
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
