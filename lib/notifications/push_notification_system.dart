import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:latlong2/latlong.dart';
import 'package:just_audio/just_audio.dart';
import '../global/global.dart';
import '../models/user_ride_request_info.dart';
import '../notifications/notification_dialog_box.dart';

class PushNotificationSystem {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  /// Initialize cloud messaging and set up listeners
  Future<void> initializeCloudMessaging(BuildContext context) async {
    // Request notification permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Handle notification when app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      print('App opened from terminated state with notification');

      final rideRequestId = message.data["rideRequestId"];
      if (rideRequestId == null) {
        print('No rideRequestId in notification data');
        return;
      }

      readUserRideRequestInformation(rideRequestId, context);
    });

    // Handle notification when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      final rideRequestId = message.data["rideRequestId"];
      if (rideRequestId == null) {
        print('No rideRequestId in notification data');
        return;
      }

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }

      readUserRideRequestInformation(rideRequestId, context);
    });

    // Handle notification when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background with notification');
      print('Message data: ${message.data}');

      final rideRequestId = message.data["rideRequestId"];
      if (rideRequestId == null) {
        print('No rideRequestId in notification data');
        return;
      }

      readUserRideRequestInformation(rideRequestId, context);
    });
  }

  /// Read ride request information from Firebase and show dialog
  void readUserRideRequestInformation(
      String rideRequestId, BuildContext context) async {
    try {
      print('Reading ride request: $rideRequestId');

      final snap = await FirebaseDatabase.instance
          .ref()
          .child("All Ride Requests")
          .child(rideRequestId)
          .once();

      if (snap.snapshot.value == null) {
        print('No ride request found for ID: $rideRequestId');
        Fluttertoast.showToast(
          msg: "No ride request found",
          backgroundColor: Colors.red,
        );
        return;
      }

      final data = snap.snapshot.value as Map;
      print('Ride request data loaded successfully');

      // Play notification sound
      try {
        await audioPlayer.setAsset("music/music_notification.mp3");
        audioPlayer.play();
      } catch (e) {
        print('Error playing notification sound: $e');
        // Continue even if sound fails
      }

      // Create UserRideRequestInfo object
      UserRideRequestInfo userRideRequestInfo = UserRideRequestInfo(
        originLatLng: LatLng(
          double.parse(data["origin"]["latitude"].toString()),
          double.parse(data["origin"]["longitude"].toString()),
        ),
        destinationLatLng: LatLng(
          double.parse(data["destination"]["latitude"].toString()),
          double.parse(data["destination"]["longitude"].toString()),
        ),
        originAddress: data["originAddress"]?.toString(),
        destinationAddress: data["destinationAddress"]?.toString(),
        rideRequestId: rideRequestId,
        userName: data["userName"]?.toString(),
        userPhone: data["userPhone"]?.toString(),
      );

      print('Showing ride request dialog');

      // Show notification dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => NotificationDialogBox(
          userRideRequestInfo: userRideRequestInfo,
        ),
      );
    } catch (e) {
      print('Error reading ride request: $e');
      Fluttertoast.showToast(
        msg: "Error loading ride request: $e",
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  /// Generate FCM token and save to Firebase
  Future<void> generateAndGetToken() async {
    try {
      String? token = await messaging.getToken();

      if (token == null) {
        print('Failed to get FCM token');
        return;
      }

      print('FCM Token: $token');

      // Save token to Firebase
      await FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(firebaseAuth.currentUser!.uid)
          .child("token")
          .set(token);

      print('FCM token saved to Firebase');

      // Subscribe to topics
      await messaging.subscribeToTopic("allDrivers");
      await messaging.subscribeToTopic("allUsers");

      print('Subscribed to notification topics');
    } catch (e) {
      print('Error generating FCM token: $e');
    }
  }

  /// Handle token refresh
  void onTokenRefresh() {
    messaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');

      // Save new token to Firebase
      FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(firebaseAuth.currentUser!.uid)
          .child("token")
          .set(newToken);
    });
  }

  /// Delete token (call when driver logs out)
  Future<void> deleteToken() async {
    try {
      await messaging.deleteToken();
      print('FCM token deleted');

      // Remove token from Firebase
      await FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(firebaseAuth.currentUser!.uid)
          .child("token")
          .remove();

      // Unsubscribe from topics
      await messaging.unsubscribeFromTopic("allDrivers");
      await messaging.unsubscribeFromTopic("allUsers");

      print('Unsubscribed from notification topics');
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }
}