import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';
import 'directions_details_info.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;
UserModel? userModelCurrentInfo;

// User info
String userName = "";
String userEmail = "";
String userPhone = "";

// Drop off location
String userDropOffLocation = "";

// Trip details
DirectionsDetailsInfo? tripDirectionDetailsInfo;