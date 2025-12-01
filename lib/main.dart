import 'package:flutter/material.dart';
import 'splash.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo',
      themeMode: themeMode.system,
      theme: MyThemes.lightTheme,
      darkTheme: MyThemes.darkTheme,
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
