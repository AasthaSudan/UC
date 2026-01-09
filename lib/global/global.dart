import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../models/driver_data.dart';
import '../models/user_model.dart';
import '../info/directions_details_info.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

User? currentUser;
UserModel? userModelCurrentInfo;

Position? driverCurrentPosition;

DriverData onlineDriverData = DriverData();

StreamSubscription<Position>? streamSubscriptionPosition;
StreamSubscription<Position>? streamSubscriptionDriverLivePosition;

AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();

String userName = "";
String userEmail = "";
String userPhone = "";

DirectionsDetailsInfo? tripDirectionDetailsInfo;
List driversList = [];
String? userFcmToken;
String? driverFcmToken;

String driverCarDetails = "";
String driverName = "";
String driverPhone = "";

double countRatingStars = 0.0;
String titleStarsRating = "";

DatabaseReference? referenceRideRequest;
