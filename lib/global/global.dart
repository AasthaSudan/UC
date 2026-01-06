import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/driver_data.dart';
import '../models/user_model.dart';
import '../info/directions_details_info.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

User? currentUser;
UserModel? userModelCurrentInfo;

Position? driverCurrentPosition;

DriverData onlineDriverData = DriverData();

StreamSubscription<Position>? streamSubscriptionPosition;
StreamSubscription<Position>? streamSubscriptionDriverLivePosition;

String userName = "";
String userEmail = "";
String userPhone = "";

String userDropOffLocation = "";

DirectionsDetailsInfo? tripDirectionDetailsInfo;
