import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/user_ride_request_info.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../info/app_info.dart';
import '../info/directions_details_info.dart';
import '../assistants/assistant_methods.dart';

class NewRideScreen extends StatefulWidget {
  const NewRideScreen({super.key});

  @override
  State<NewRideScreen> createState() => _NewRideScreenState();
}

class _NewRideScreenState extends State<NewRideScreen> {
  LatLng? pickLocation;
  String? _address;
  final MapController mapController = MapController();

  String? buttonTitle="Arrived";
  Color? buttonColor=Colors.green;


  static const LatLng _initialLocation = LatLng(28.6139, 77.2090);
  static const LatLng _southWestBound = LatLng(6.5546, 68.1113);
  static const LatLng _northEastBound = LatLng(35.6745, 97.3953);
  static final LatLngBounds _indiaBounds = LatLngBounds(_southWestBound, _northEastBound);

  Set<Marker> markers = Set<Marker>();
  Set<Circle> circles = Set<Circle>();
  Set<Polyline> polyLines = Set<Polyline>();
  List<LatLng> polylinePoints = [];
  PolylinePoints polylinePointsInstance = PolylinePoints();
  double mapPadding = 0;
  BitmapDescriptor? carIcon;
  Position? currentPosition;
  String rideRequestStatus = "accepted";
  String durationFromOriginToDestination = "";
  bool isRequestingDirection = false;

  Future<void> drawPolyLineFromOriginToDestination(
      LatLng driverCurrentLatLng, LatLng userPickUpLatLng, bool darkTheme) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        userPickUpLatLng, driverCurrentLatLng);

    Navigator.pop(context);

    List<PointLatLng> decodedPolyLinePointsResult = polylinePointsInstance.decodePolyline(directionDetailsInfo.e_points!);

    polylinePoints.clear();
    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        polylinePoints.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polyLines.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
        polylineId: PolylineId("PolylineID"),
        points: polylinePoints,
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polyLines.add(polyline);
    });

    LatLngBounds bounds;
    if (userPickUpLatLng.latitude > driverCurrentLatLng.latitude &&
        userPickUpLatLng.longitude > driverCurrentLatLng.longitude) {
      bounds = LatLngBounds(southwest: driverCurrentLatLng, northeast: userPickUpLatLng);
    } else if (userPickUpLatLng.longitude > driverCurrentLatLng.longitude) {
      bounds = LatLngBounds(
        southwest: LatLng(userPickUpLatLng.latitude, driverCurrentLatLng.longitude),
        northeast: LatLng(driverCurrentLatLng.latitude, userPickUpLatLng.longitude),
      );
    } else if (userPickUpLatLng.latitude > driverCurrentLatLng.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(driverCurrentLatLng.latitude, userPickUpLatLng.longitude),
        northeast: LatLng(userPickUpLatLng.latitude, driverCurrentLatLng.longitude),
      );
    } else {
      bounds = LatLngBounds(southwest: userPickUpLatLng, northeast: driverCurrentLatLng);
    }

    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 65));

    Marker originMarker=Marker(
      markerId: MarkerId("originID"),
      position: userPickUpLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    Marker destinationMarker=Marker(
      markerId: MarkerId("destinationID"),
      position: driverCurrentLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
    setState(() {
      markers.add(originMarker);
      markers.add(destinationMarker);
    });


    Circle originCircle = Circle(
      circleId: CircleId("originID"),
      strokeColor: Colors.green,
      strokeWidth: 3,
      radius: 12,
      fillColor: Colors.greenAccent,
      center: originLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: CircleId("destinationID"),
      strokeColor: Colors.red,
      strokeWidth: 3,
      radius: 12,
      fillColor: Colors.redAccent,
      center: destinationLatLng,
    );

    setState(() {
      circles.add(originCircle);
      circles.add(destinationCircle);
    });
  }

  getDriverLocationUpdatesAtRealTime() async {
    LatLng oldLatLng = LatLng(0, 0);

    streamSubscription = Geolocator.getPositionStream().listen((Position position) {
      currentPosition = position;
      onlineDriverCurrentPosition = position;

      LatLng latLngLiveDriverPosition = LatLng(onlineDriverCurrentPosition!.latitude, onlineDriverCurrentPosition!.longitude);

      Marker liveDriverMarker = Marker(
        markerId: MarkerId("liveDriver"),
        position: latLngLiveDriverPosition,
        icon: iconAnimatedMarker!,
        infoWindow: InfoWindow(
          title: "Current Location",
        ),
      );

      setState(() {
        CameraPosition cameraPosition = CameraPosition(target: latLngLiveDriverPosition, zoom: 18);
        mapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        markers.removeWhere((marker) => marker.markerId.value == "liveDriver");
        markers.add(liveDriverMarker);

      });

      oldLatLng = latLngLiveDriverPosition;
      updateDriversLocationAtRealTime();

      Map driverLatLngMap = {
        "latitude": onlineDriverCurrentPosition!.latitude.toString(),
        "longitude": onlineDriverCurrentPosition!.longitude.toString(),
      };

      FirebaseDatabase.instance.ref().child("All Ride Requests").child(widget.userRideRequestDetails!.rideRequestId!).child("driver_location").set(driverLatLngMap);

    });
  }

  updateDurationTimeAtRealTime() async {
    if(isRequestingDirection == false) {
      isRequestingDirection = true;

      if (onlineDriverCurrentPosition == null) {
        return;
      }

      var originLatLng = LatLng(
        onlineDriverCurrentPosition!.latitude,
        onlineDriverCurrentPosition!.longitude,
      );

      var destinationLatLng;

      if (rideRequestStatus == "accepted") {
        destinationLatLng = widget.userRideRequestDetails!.originLatLng;
      }
      else {
        destinationLatLng = widget.userRideRequestDetails!.destinationLatLng;
      }

      var directionDetailsInfo = await AssistantMethods
          .obtainOriginToDestinationDirectionDetails(
        originLatLng,
        destinationLatLng,
      );

      if (directionDetailsInfo != null) {
        setState(() {
          durationFromOriginToDestination = directionDetailsInfo.duration_text!;
        });
      }

      isRequestingDirection = false;
    }
  }

  @override
  void initState() {
    super.initState();
    saveAssignedDriverInfo();
  }

  saveAssignedDriverInfo() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("All Ride Requests").child(widget.userRideRequestDetails!.rideRequestId!);
    Map driverInfoMap = {
      "latitude": currentPosition!.latitude.toString(),
      "longitude": currentPosition!.longitude.toString(),
    };

    if(databaseReference.child("driverId")!="waiting") {
      databaseReference.child("driverId").set(onlineDriverData.id);
      databaseReference.child("driver_name").set(onlineDriverData.name);
      databaseReference.child("driver_phone").set(onlineDriverData.phone);
      databaseReference.child("ratings").set(onlineDriverData.ratings);
      databaseReference.child("car_details").set(onlineDriverData.carDetails);
      databaseReference.child("driver_location").set(driverInfoMap);
      databaseReference.child("status").set("accepted");

      saveRideRequestIdToDriverHistory();
    }
    else {
      Fluttertoast.showToast(msg: "This ride request has already been accepted by another driver.\n Please try again later.");
      Navigator.push(context, MaterialPageRoute(builder: (context) => SplashScreen()));
    }
  }

  saveRideRequestIIdToDriverHistory() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("Drivers").child(firebaseAuth.currentUser!.uid).child("history");
    ref.child(widget.userRideRequestDetails!.rideRequestId!).set(true);


    }
  }

  createCarIconMarker() {
    if(carIcon == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(2,2),
          BitmapDescriptor.fromAssetImage(
              ImageConfiguration(),
              "assets/images/car.png"
          ).then((value) {
        carIcon = value;
      });
    }
  }

endTripNow() {
  showDialog(
    context: context,
    builder: (BuildContext context) => ProgressDialog(
      message: "Please wait...",
    ),
  );

  var currentDriverPositionLatLng = LatLng(
    onlineDriverCurrentPosition!.latitude,
    onlineDriverCurrentPosition!.longitude,
  );

  var tripDirectionDetails = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
    widget.userRideRequestDetails!.originLatLng!,
  );
}

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: pickLocation ?? _initialLocation,
              zoom: 15.0,
            ),
            mapController: mapController,
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: markers.toList()),
              CircleLayer(circles: circles.toList()),
              PolylineLayer(polylines: polyLines.toList()),
            ],
          ),

          var driverCurrentLatLng=Latlng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
          var userPickUpLatLng=widget.userRideRequestDetails!.originLatLng;
          drawPolyLineFromOriginToDestination(driverCurrentLatLng, userPickUpLatLng!, darkTheme);
          getDriverLocationUpdatesAtRealTime();
          updateDurationTimeAtRealTime();
          createCarIconMarker();
  },


          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      spreadRadius: 0.5,
                      blurRadius: 18,
                      offset: Offset(0.6, 0.6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text(
                        durationFromOriginToDestination,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkTheme ? Colors.amber.shade400 : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Divider(thickness: 1, color: darkTheme ? Colors.amber.shade400 : Colors.grey),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.userRideRequestDetails!.userName!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: darkTheme ? Colors.amber.shade400 : Colors.black,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.phone,
                              color: darkTheme ? Colors.amber.shade400 : Colors.black,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10),

                      Row(
                        children: [
                          Image.asset(
                            "assets/images/pickicon.png",
                            height: 30,
                            width: 30,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.userRideRequestDetails!.originAddress!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkTheme ? Colors.amber.shade400 : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/desticon.png",
                            height: 30,
                            width: 30,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.userRideRequestDetails!.destinationAddress!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkTheme ? Colors.amber.shade400 : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                      SizedBox(height: 10),

                      Divider(
                        thickness: 1,
                        color: darkTheme ? Colors.amber.shade400 : Colors.grey,
                      ),

                      SizedBox(height: 10),

                      ElevatedButton.icon(
                        onPressed: () {
                          if(rideRequestStatus == "accepted") {
                            rideRequestStatus = "arrived";

                            FirebaseDatabase.instance.ref().child("All Ride Requests").child(widget.userRideRequestDetails!.rideRequestId!).child("status").set(rideRequestStatus);

                            setState(() {
                              buttonTitle = "Start Trip";
                              buttonColor = Colors.green;
                            });

                            showDialog(
                              context: context,
                              builder: (BuildContext context) => ProgressDialog(
                              message: "Please wait...",
                            ),
                          );

                            await drawPolyLineFromOriginToDestination(
                              widget.userRideRequestDetails!.originLatLng!,
                              widget.userRideRequestDetails!.destinationLatLng!,
                              darkTheme,
                            );
                            Navigator.pop(context);
                          }
                          else if(rideRequestStatus == "arrived") {
                            rideRequestStatus = "onTrip";

                            FirebaseDatabase.instance.ref().child("All Ride Requests").child(widget.userRideRequestDetails!.rideRequestId!).child("status").set(rideRequestStatus);

                            setState(() {
                              buttonTitle = "End Trip";
                              buttonColor = Colors.red;
                            });
                          }

                          else if(rideRequestStatus == "onTrip") {
                            endTripNow();






                          icon: Icon(
                            Icons.directions_car,
                            color: darkTheme ? Colors.black : Colors.white,
                            size: 25,
                            ),
                            label: Text(
                              buttonTitle!,
                              style: TextStye(
                              color: darkTheme ? Colors.black : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              ),
                            ),

                          );

)




                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
