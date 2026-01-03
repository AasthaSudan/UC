import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';
import 'directions_details_info.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;
UserModel? userModelCurrentInfo;

String userName = "";
String userEmail = "";
String userPhone = "";

String userDropOffLocation = "";

DirectionsDetailsInfo? tripDirectionDetailsInfo;