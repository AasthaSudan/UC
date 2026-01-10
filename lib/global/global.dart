import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../models/driver_data.dart';
import '../models/user_model.dart';
import '../info/directions_details_info.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:just_audio/just_audio.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

User? currentUser;
UserModel? userModelCurrentInfo;

Position? driverCurrentPosition;

DriverData onlineDriverData = DriverData();

StreamSubscription<Position>? streamSubscriptionPosition;
StreamSubscription<Position>? streamSubscriptionDriverLivePosition;

AudioPlayer audioPlayer = AudioPlayer();

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

Future<void> readCurrentUserInfo() async {
  currentUser = firebaseAuth.currentUser;

  if (currentUser == null) {
    print("Error: No user logged in");
    return;
  }

  try {
    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(currentUser!.uid);

    DataSnapshot snapshot = await userRef.get();

    if (snapshot.exists && snapshot.value != null) {
      userModelCurrentInfo = UserModel.fromSnapshot(snapshot);

      userName = userModelCurrentInfo?.name ?? '';
      userEmail = userModelCurrentInfo?.email ?? '';
      userPhone = userModelCurrentInfo?.phone ?? '';

      print("User data loaded successfully");
      print("Name: ${userModelCurrentInfo?.name}");
      print("Email: ${userModelCurrentInfo?.email}");
      print("Phone: ${userModelCurrentInfo?.phone}");
    } else {
      print("Error: User information is null - No data found in database");
    }
  } catch (e) {
    print("Error reading user info: $e");
  }
}