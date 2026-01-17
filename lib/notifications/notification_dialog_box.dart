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
            const SizedBox(height: 20),

            // Vehicle icon based on car type
            Image.asset(
              onlineDriverData.car_type == "Car"
                  ? "images/car.png"
                  : onlineDriverData.car_type == "CNG"
                  ? "images/cng.png"
                  : "images/bike.png",
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if image not found
                return Icon(
                  Icons.directions_car,
                  size: 80,
                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                );
              },
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
                  // Pickup location
                  _locationRow(
                    icon: "images/pickicon.png",
                    fallbackIcon: Icons.location_on,
                    iconColor: Colors.green,
                    text: widget.userRideRequestInfo?.originAddress ?? "Pickup location",
                    darkTheme: darkTheme,
                  ),

                  const SizedBox(height: 20),

                  // Drop location
                  _locationRow(
                    icon: "images/desticon.png",
                    fallbackIcon: Icons.location_on,
                    iconColor: Colors.red,
                    text: widget.userRideRequestInfo?.destinationAddress ?? "Drop location",
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

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cancel button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        // Stop audio
                        audioPlayer.pause();
                        audioPlayer.stop();
                        audioPlayer = AudioPlayer();

                        Navigator.pop(context);
                      },
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Accept button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        // Stop audio
                        audioPlayer.pause();
                        audioPlayer.stop();
                        audioPlayer = AudioPlayer();

                        acceptRideRequest(context);
                      },
                      child: const Text(
                        "ACCEPT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
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
    required IconData fallbackIcon,
    required Color iconColor,
    required String text,
    required bool darkTheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Try to load image, fallback to icon
        Image.asset(
          icon,
          height: 30,
          width: 30,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              fallbackIcon,
              color: iconColor,
              size: 30,
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: darkTheme ? Colors.white : Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void acceptRideRequest(BuildContext context) async {
    // Check if driver is idle (not on another ride)
    try {
      final snap = await FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(firebaseAuth.currentUser!.uid)
          .child("newRideStatus")
          .once();

      if (snap.snapshot.value == "idle") {
        // Update driver status to accepted
        await FirebaseDatabase.instance
            .ref()
            .child("drivers")
            .child(firebaseAuth.currentUser!.uid)
            .child("newRideStatus")
            .set("accepted");

        // Pause live location updates
        AssistantMethods.pauseLiveLocationUpdates();

        // Close the dialog
        if (!mounted) return;
        Navigator.pop(context);

        // Navigate to NewRideScreen with ride details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewRideScreen(
              userRideRequestDetails: widget.userRideRequestInfo, // ✅ Fixed: Pass the ride details
            ),
          ),
        );
      } else {
        // Ride no longer available
        Fluttertoast.showToast(
          msg: "This ride request is no longer available",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );

        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error accepting ride: $e");
      Fluttertoast.showToast(
        msg: "Error accepting ride: $e",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}