import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:latlong2/latlong.dart';
import 'package:just_audio/just_audio.dart';
import '../global/global.dart';
import '../models/user_ride_request_info.dart';
import 'package:project_1/notifications/notification_dialog_box.dart';
import 'package:project_1/screens/new_ride_screen.dart';

class PushNotificationSystem {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<void> initializeCloudMessaging(BuildContext context) async {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;

      final rideRequestId = message.data["rideRequestId"];
      if (rideRequestId == null) return;

      readUserRideRequestInformation(rideRequestId, context);
    });

    FirebaseMessaging.onMessage.listen((message) {
      final rideRequestId = message.data["rideRequestId"];
      if (rideRequestId == null) return;

      readUserRideRequestInformation(rideRequestId, context);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final rideRequestId = message.data["rideRequestId"];
      if (rideRequestId == null) return;

      readUserRideRequestInformation(rideRequestId, context);
    });
  }

  void readUserRideRequestInformation(
      String rideRequestId, BuildContext context) async {

    final snap = await FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(rideRequestId)
        .once();

    if (snap.snapshot.value == null) {
      Fluttertoast.showToast(msg: "No ride request found");
      return;
    }

    final data = snap.snapshot.value as Map;

    await audioPlayer.setAsset("music/music_notification.mp3");
    audioPlayer.play();

    UserRideRequestInfo userRideRequestInfo = UserRideRequestInfo(
      originLatLng: LatLng(
        double.parse(data["origin"]["latitude"]),
        double.parse(data["origin"]["longitude"]),
      ),
      destinationLatLng: LatLng(
        double.parse(data["destination"]["latitude"]),
        double.parse(data["destination"]["longitude"]),
      ),
      originAddress: data["originAddress"],
      destinationAddress: data["destinationAddress"],
      rideRequestId: rideRequestId,
      userName: data["userName"],
      userPhone: data["userPhone"],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => NotificationDialogBox(
        userRideRequestInfo: userRideRequestInfo,
      ),
    );
  }

  Future<void> generateAndGetToken() async {
    String? token = await messaging.getToken();

    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(firebaseAuth.currentUser!.uid)
        .child("token")
        .set(token);

    await messaging.subscribeToTopic("allDrivers");
    await messaging.subscribeToTopic("allUsers");
  }
}
