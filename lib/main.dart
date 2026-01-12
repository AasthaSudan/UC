import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_screen.dart';
import 'theme/my_themes.dart';
import 'screens/register_screen.dart';
import 'screens/splash.dart';
import 'screens/search_places_screen.dart';
import 'info/app_info.dart';
import 'firebase_options.dart';
import 'screens/car_info_screen.dart';
import 'package:project_1/tab_pages/home_tab.dart';
import '../widgets/pay_fare_amount_dialog.dart';
import 'screens/login_screen.dart';
import 'screens/new_ride_screen.dart';
import 'screens/new_ride_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child: MaterialApp(
        title: 'Trippo',
        themeMode: ThemeMode.system,
        theme: MyThemes.lightTheme,
        darkTheme: MyThemes.darkTheme,
        home: FareAmountCollectionDialog(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}