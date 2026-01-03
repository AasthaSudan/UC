import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../info/directions_details_info.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;
UserModel? userModelCurrentInfo;

String userName = "";
String userEmail = "";
String userPhone = "";

String userDropOffLocation = "";

DirectionsDetailsInfo? tripDirectionDetailsInfo;