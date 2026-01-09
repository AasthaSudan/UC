import 'package:flutter/cupertino.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationSystem {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future initializeCloudMessaging(BuildContext context) async {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if(message != null) {
        readUserRideRequestInformation(message.data["rideRequestId"], context);
      }
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
      readUserRideRequestInformation(message!.data["rideRequestId"], context);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
      readUserRideRequestInformation(message!.data["rideRequestId"], context);
    });
  }

  readUserRideRequestInformation(String rideRequestId, BuildContext context) async {
    FirebaseDatabase.instance.ref().child("All Ride Requests").child(rideRequestId).child("driverId").onValue.listen((event) async {
      if(event.snapshot.value=="waiting" || event.snapshot.value==firebaseAuth.currentUser!.uid) {
        FirebaseDatabase.instance.ref().child("All Ride Requests").child(rideRequestId).once().then((snap) {
          if(snap.snapshot.value != null) {
            audioPlayer.open(
              Audio("music/music_notification.mp3"),
              audioPlayer.play();

              double originLat=double.parse((snap.snapshot.value! as Map)["origin"]["latitude"]);
              double originLng=double.parse((snap.snapshot.value! as Map)["origin"]["longitude"]);
              double destinationLat=double.parse((snap.snapshot.value! as Map)["destination"]["latitude"]);
              double destinationLng=double.parse((snap.snapshot.value! as Map)["destination"]["longitude"]);
              String originAddress=(snap.snapshot.value! as Map)["originAddress"];
              String destinationAddress=(snap.snapshot.value! as Map)["destinationAddress"];

              String userName=(snap.snapshot.value! as Map)["userName"];
              String userPhone=(snap.snapshot.value! as Map)["userPhone"];

              String? rideRequestId=snap.snapshot.key;

              UserRideRequestInfo userRideRequestDetails=UserRideRequestInfo();
              userRideRequestInfo.originLatLng=LatLng(originLat, originLng);
              userRideRequestInfo.destinationLatLng=LatLng(destinationLat, destinationLng);
              userRideRequestInfo.originAddress=originAddress;
              userRideRequestInfo.destinationAddress=destinationAddress;
              userRideRequestInfo.rideRequestId=rideRequestId;
              userRideRequestInfo.userName=userName;
              userRideRequestInfo.userPhone=userPhone;

              showDialog(
                context: context,
                builder: (BuildContext context) => NotificationDialogBox(
                  userRideRequestDetails: userRideRequestDetails,
                ),
              );
            }
            else {
              Fluttertoast.showToast(msg: "No ride request found");
            }
          });
        }
      else {
        Fluttertoast.showToast(msg: "Ride request cancelled");
        Navigator.pop(context);
      }
    });
  }

  Future generateAndGetToken() async {
    String? deviceToken = await messaging.getToken();
    print("This is device token: $deviceToken");

    FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(firebaseAuth.currentUser!.uid)
        .child("token")
        .set("$deviceToken");

    messaging.subscribeToTopic("allDrivers");
  messaging.subscribeToTopic("allUsers");

  }
}