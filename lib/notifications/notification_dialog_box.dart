import 'package:flutter/material.dart';
import 'package:project_1/models/user_ride_request_info.dart';

class NotificationDialogBox extends StatefulWidget {
  UserRideRequestInfo? userRideRequestInfo;

  NotificationDialogBox({this.userRideRequestInfo});

  @override
  State<NotificationDialogBox> createState() => _NotificationDialogBoxState();
}

class _NotificationDialogBoxState extends State<NotificationDialogBox> {
  @override
  Widget build(BuildContext context) {
    bool darkTheme=MediaQuery.of(context).platfromBrightness==Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        margin: EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: darkTheme?Colors.black:Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              onlineDriverData.car_type=="Car"?"images/car.png",
              : onlineDriverData.car_type=="CNG"?"images/cng.png",
              : "images/bike.png",
            ),

          SizedBox(height: 10,),

          Text("New Ride Request",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkTheme?Colors.amber.shade400:Colors.blue,
            ),
          ),

          SizedBox(height: 14,),

          Divider(
            height: 2,
            thickness: 2,
            color: darkTheme?Colors.amber.shade400:Colors.blue,
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                children: [
                  Image.asset(
                    "images/pickicon.png",
                    height: 30,
                    width: 30,
                  ),

                SizedBox(width: 10,),

                Expanded(
                  child: Container(
                    child: Text(
                      widget.userRideRequestDetails!.originAddress!,
                      style: TextStyle(
                        fontSize: 16,
                        color: darkTheme?Colors.amber.shade400:Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),

        SizedBox(height: 20,),

        Row(
          children: [
            Image.asset(
              "images/desticon.png",
              height: 30,
              width: 30,
        ),

        SizedBox(width: 10,),

        Expanded(
          child: Container(
            child: Text(
              widget.userRideRequestDetails!.destinationAddress!,
              style: TextStyle(
                fontSize: 16,
                color: darkTheme?Colors.amber.shade400:Colors.blue,
              ),
            ),
          ),
        ),
      ],
    ),
  ],
),
),

            Divider(
              height: 2,
              thickness: 2,
              color: darkTheme?Colors.amber.shade400:Colors.blue,
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),

                    child: Text(
                      "Cancel".toUpperCase(),
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
            ),

                  SizedBox(width: 20,),

                  ElevatedButton(
                    onPressed: () {
                      audioPlayer.pause();
                      audioPlayer.stop();
                      audioPlayer = AssetsAudioPlayer();

                      acceptRideRequest(context);
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),


                    child: Text(
                      "Accept".toUpperCase(),
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  ),








          ],
        ),
      ),
    );
  }

  acceptRideRequest(BuildContext context) async {
    FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(firebaseAuth.currentUser!.uid)
        .child("newRideStatus")
        .once()
        .then((snap) {

        if(snap.snapshot.value == "idle") {
          FirebaseDatabase.instance.ref()
              .child("drivers")
              .child(firebaseAuth.currentUser!.uid)
              .child("newRideStatus")
              .set("accepted");
        }

        AssistantMethods. pauseLiveLocationUpdates();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewRideScreen(),
          ),
        );
        else {
          Fluttertoast.showToast(msg: "This ride request is not available");
      }
    });
  }
}
