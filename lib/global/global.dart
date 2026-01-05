import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_1/models/driver_data.dart';
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