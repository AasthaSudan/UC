import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import '../global/global.dart';
import '../assistants/assistant_methods.dart';
import '../models/user_ride_request_info.dart';
import '../screens/new_ride_screen.dart';

class NotificationDialogBox extends StatefulWidget {
  final UserRideRequestInfo? userRideRequestInfo;

  const NotificationDialogBox({super.key, this.userRideRequestInfo});

  @override
  State<NotificationDialogBox> createState() => _NotificationDialogBoxState();
}

class _NotificationDialogBoxState extends State<NotificationDialogBox> {
  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: darkTheme ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              onlineDriverData.car_type == "Car"
                  ? "images/car.png"
                  : onlineDriverData.car_type == "CNG"
                  ? "images/cng.png"
                  : "images/bike.png",
              height: 120,
            ),

            const SizedBox(height: 10),

            Text(
              "New Ride Request",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkTheme
                    ? Colors.amber.shade400
                    : Colors.blue,
              ),
            ),

            const SizedBox(height: 14),

            Divider(
              thickness: 2,
              color: darkTheme
                  ? Colors.amber.shade400
                  : Colors.blue,
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _locationRow(
                    icon: "images/pickicon.png",
                    text: widget.userRideRequestInfo!.originAddress!,
                    darkTheme: darkTheme,
                  ),

                  const SizedBox(height: 20),

                  _locationRow(
                    icon: "images/desticon.png",
                    text: widget.userRideRequestInfo!.destinationAddress!,
                    darkTheme: darkTheme,
                  ),
                ],
              ),
            ),

            Divider(
              thickness: 2,
              color: darkTheme
                  ? Colors.amber.shade400
                  : Colors.blue,
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCEL"),
                  ),

                  const SizedBox(width: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      audioPlayer.stop();
                      acceptRideRequest(context);
                    },
                    child: const Text("ACCEPT"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationRow({
    required String icon,
    required String text,
    required bool darkTheme,
  }) {
    return Row(
      children: [
        Image.asset(icon, height: 30, width: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: darkTheme
                  ? Colors.amber.shade400
                  : Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  void acceptRideRequest(BuildContext context) {
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(firebaseAuth.currentUser!.uid)
        .child("newRideStatus")
        .once()
        .then((snap) {
      if (snap.snapshot.value == "idle") {
        FirebaseDatabase.instance
            .ref()
            .child("drivers")
            .child(firebaseAuth.currentUser!.uid)
            .child("newRideStatus")
            .set("accepted");

        AssistantMethods.pauseLiveLocationUpdates();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewRideScreen(),
          ),
        );
      } else {
        Fluttertoast.showToast(
            msg: "This ride request is no longer available");
      }
    });
  }
}
