import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_ride_request_info.dart';
import '../info/directions_details_info.dart';
import '../assistants/assistant_methods.dart';
import '../global/global.dart';
import '../widgets/openroute_service.dart';

class NewRideScreen extends StatefulWidget {
  final UserRideRequestInfo? userRideRequestDetails;

  const NewRideScreen({
    super.key,
    required this.userRideRequestDetails,
  });

  @override
  State<NewRideScreen> createState() => _NewRideScreenState();
}

class _NewRideScreenState extends State<NewRideScreen> {
  final MapController mapController = MapController();

  String buttonTitle = "Arrived";
  Color buttonColor = Colors.green;

  static const LatLng _initialLocation = LatLng(28.6139, 77.2090);
  static const LatLng _southWestBound = LatLng(6.5546, 68.1113);
  static const LatLng _northEastBound = LatLng(35.6745, 97.3953);
  static final LatLngBounds _indiaBounds = LatLngBounds(_southWestBound, _northEastBound);

  List<Marker> markers = [];
  List<CircleMarker> circles = [];
  List<Polyline> polylines = [];
  List<LatLng> polylinePoints = [];
  final OpenRouteService _routeService = OpenRouteService();

  Position? currentPosition;
  Position? onlineDriverCurrentPosition;
  String rideRequestStatus = "accepted";
  String durationFromOriginToDestination = "";
  bool isRequestingDirection = false;
  StreamSubscription<Position>? streamSubscription;

  Future<void> drawPolyLineFromOriginToDestination(
      LatLng originLatLng, LatLng destinationLatLng, bool darkTheme) async {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        originLatLng, destinationLatLng);

    if (!mounted) return;
    Navigator.pop(context);

    if (directionDetailsInfo == null) {
      Fluttertoast.showToast(msg: "Could not get directions");
      return;
    }

    print("Got direction details, decoding polyline...");
    polylinePoints = _routeService.decodePolyline(directionDetailsInfo.e_points!);
    print("Decoded ${polylinePoints.length} route points");

    polylines.clear();

    setState(() {
      Polyline polyline = Polyline(
        points: polylinePoints,
        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
        strokeWidth: 5.0,
      );
      polylines.add(polyline);
    });

    LatLngBounds bounds = LatLngBounds.fromPoints([originLatLng, destinationLatLng]);

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );

    Marker originMarker = Marker(
      point: originLatLng,
      width: 80,
      height: 80,
      child: const Icon(
        Icons.location_on,
        color: Colors.green,
        size: 45,
      ),
    );

    Marker destinationMarker = Marker(
      point: destinationLatLng,
      width: 80,
      height: 80,
      child: const Icon(
        Icons.location_on,
        color: Colors.red,
        size: 45,
      ),
    );

    CircleMarker originCircle = CircleMarker(
      point: originLatLng,
      color: Colors.greenAccent.withOpacity(0.3),
      borderColor: Colors.green,
      borderStrokeWidth: 3,
      radius: 12,
    );

    CircleMarker destinationCircle = CircleMarker(
      point: destinationLatLng,
      color: Colors.redAccent.withOpacity(0.3),
      borderColor: Colors.red,
      borderStrokeWidth: 3,
      radius: 12,
    );

    setState(() {
      markers.clear();
      markers.add(originMarker);
      markers.add(destinationMarker);

      circles.clear();
      circles.add(originCircle);
      circles.add(destinationCircle);
    });
  }

  getDriverLocationUpdatesAtRealTime() async {
    streamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      currentPosition = position;
      onlineDriverCurrentPosition = position;

      LatLng latLngLiveDriverPosition = LatLng(
        onlineDriverCurrentPosition!.latitude,
        onlineDriverCurrentPosition!.longitude,
      );

      Marker liveDriverMarker = Marker(
        point: latLngLiveDriverPosition,
        width: 80,
        height: 80,
        child: const Icon(
          Icons.directions_car,
          color: Colors.blue,
          size: 45,
        ),
      );

      setState(() {
        mapController.move(latLngLiveDriverPosition, 16);

        markers.removeWhere((marker) =>
        marker.child is Icon && (marker.child as Icon).icon == Icons.directions_car
        );
        markers.add(liveDriverMarker);
      });

      updateDurationTimeAtRealTime();

      Map<String, String> driverLatLngMap = {
        "latitude": onlineDriverCurrentPosition!.latitude.toString(),
        "longitude": onlineDriverCurrentPosition!.longitude.toString(),
      };

      FirebaseDatabase.instance
          .ref()
          .child("All Ride Requests")
          .child(widget.userRideRequestDetails!.rideRequestId!)
          .child("driver_location")
          .set(driverLatLngMap);
    });
  }

  updateDurationTimeAtRealTime() async {
    if (isRequestingDirection == false) {
      isRequestingDirection = true;

      if (onlineDriverCurrentPosition == null) {
        isRequestingDirection = false;
        return;
      }

      var originLatLng = LatLng(
        onlineDriverCurrentPosition!.latitude,
        onlineDriverCurrentPosition!.longitude,
      );

      LatLng? destinationLatLng;

      if (rideRequestStatus == "accepted") {
        destinationLatLng = widget.userRideRequestDetails!.originLatLng;
      } else {
        destinationLatLng = widget.userRideRequestDetails!.destinationLatLng;
      }

      if (destinationLatLng == null) {
        isRequestingDirection = false;
        return;
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

  @override
  void dispose() {
    streamSubscription?.cancel();
    _routeService.dispose();
    super.dispose();
  }

  saveAssignedDriverInfo() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentPosition = position;
      onlineDriverCurrentPosition = position;

      DatabaseReference databaseReference = FirebaseDatabase.instance
          .ref()
          .child("All Ride Requests")
          .child(widget.userRideRequestDetails!.rideRequestId!);

      DataSnapshot snapshot = await databaseReference.child("driverId").get();

      if (snapshot.value == null || snapshot.value == "waiting") {
        Map<String, String> driverInfoMap = {
          "latitude": currentPosition!.latitude.toString(),
          "longitude": currentPosition!.longitude.toString(),
        };

        await databaseReference.child("driverId").set(onlineDriverData.id);
        await databaseReference.child("driver_name").set(onlineDriverData.name);
        await databaseReference.child("driver_phone").set(onlineDriverData.phone);
        await databaseReference.child("ratings").set(onlineDriverData.ratings);
        await databaseReference.child("car_details").set(
            "${onlineDriverData.car_color} ${onlineDriverData.car_model} - ${onlineDriverData.car_number}"
        );
        await databaseReference.child("driver_location").set(driverInfoMap);
        await databaseReference.child("status").set("accepted");

        saveRideRequestIdToDriverHistory();

        if (mounted) {
          bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
          var driverCurrentLatLng = LatLng(currentPosition!.latitude, currentPosition!.longitude);
          var userPickUpLatLng = widget.userRideRequestDetails!.originLatLng;

          if (userPickUpLatLng != null) {
            await drawPolyLineFromOriginToDestination(
                driverCurrentLatLng,
                userPickUpLatLng,
                darkTheme
            );
          }
          getDriverLocationUpdatesAtRealTime();
        }
      } else {
        Fluttertoast.showToast(
          msg: "This ride request has already been accepted by another driver.\nPlease try again later.",
        );
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print("Error in saveAssignedDriverInfo: $e");
      Fluttertoast.showToast(msg: "Error getting location: $e");
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  saveRideRequestIdToDriverHistory() async {
    DatabaseReference ref = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(firebaseAuth.currentUser!.uid)
        .child("history");

    ref.child(widget.userRideRequestDetails!.rideRequestId!).set(true);
  }

  endTripNow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    var currentDriverPositionLatLng = LatLng(
      onlineDriverCurrentPosition!.latitude,
      onlineDriverCurrentPosition!.longitude,
    );

    var tripDirectionDetails = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
      widget.userRideRequestDetails!.originLatLng!,
      currentDriverPositionLatLng,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (tripDirectionDetails == null) {
      Fluttertoast.showToast(msg: "Error calculating fare");
      return;
    }

    double totalFareAmount = AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetails);

    await FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(widget.userRideRequestDetails!.rideRequestId!)
        .child("fareAmount")
        .set(totalFareAmount.toString());

    await FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(widget.userRideRequestDetails!.rideRequestId!)
        .child("status")
        .set("ended");

    streamSubscription?.cancel();

    if (mounted) {
      bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          backgroundColor: darkTheme ? Colors.black : Colors.white,
          title: Text(
            "Trip Completed!",
            style: TextStyle(
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Total Fare Amount",
                style: TextStyle(
                  color: darkTheme ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "₹${totalFareAmount.toStringAsFixed(0)}",
                style: TextStyle(
                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                "Collect Cash",
                style: TextStyle(
                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    saveFareAmountToDriverEarnings(totalFareAmount);
  }

  saveFareAmountToDriverEarnings(double totalFareAmount) async {
    DatabaseReference earningsRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(firebaseAuth.currentUser!.uid)
        .child("earnings");

    DataSnapshot snapshot = await earningsRef.get();

    if (snapshot.value != null) {
      double oldEarnings = double.parse(snapshot.value.toString());
      double driverTotalEarnings = oldEarnings + totalFareAmount;
      await earningsRef.set(driverTotalEarnings.toStringAsFixed(2));
    } else {
      await earningsRef.set(totalFareAmount.toStringAsFixed(2));
    }
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      Fluttertoast.showToast(msg: "Could not launch phone dialer");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: widget.userRideRequestDetails?.originLatLng ?? _initialLocation,
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: _indiaBounds,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              PolylineLayer(polylines: polylines),
              CircleLayer(circles: circles),
              MarkerLayer(markers: markers),
            ],
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: darkTheme ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: darkTheme ? Colors.grey.shade800 : Colors.grey.shade300,
                    spreadRadius: 0.5,
                    blurRadius: 16,
                    offset: const Offset(0.6, 0.6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      durationFromOriginToDestination.isNotEmpty
                          ? durationFromOriginToDestination
                          : "Calculating...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      thickness: 1,
                      color: darkTheme ? Colors.amber.shade400 : Colors.grey,
                    ),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.userRideRequestDetails?.userName ?? "User",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: darkTheme ? Colors.amber.shade400 : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (widget.userRideRequestDetails?.userPhone != null) {
                              makePhoneCall(widget.userRideRequestDetails!.userPhone!);
                            } else {
                              Fluttertoast.showToast(msg: "Phone number not available");
                            }
                          },
                          icon: Icon(
                            Icons.phone,
                            color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.userRideRequestDetails?.originAddress ?? "Pickup location",
                            style: TextStyle(
                              fontSize: 16,
                              color: darkTheme ? Colors.white : Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.userRideRequestDetails?.destinationAddress ?? "Drop location",
                            style: TextStyle(
                              fontSize: 16,
                              color: darkTheme ? Colors.white : Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    Divider(
                      thickness: 1,
                      color: darkTheme ? Colors.amber.shade400 : Colors.grey,
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (rideRequestStatus == "accepted") {
                            setState(() {
                              rideRequestStatus = "arrived";
                              buttonTitle = "Start Trip";
                              buttonColor = Colors.green;
                            });

                            await FirebaseDatabase.instance
                                .ref()
                                .child("All Ride Requests")
                                .child(widget.userRideRequestDetails!.rideRequestId!)
                                .child("status")
                                .set(rideRequestStatus);

                            if (!mounted) return;

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            if (widget.userRideRequestDetails!.originLatLng != null &&
                                widget.userRideRequestDetails!.destinationLatLng != null) {
                              await drawPolyLineFromOriginToDestination(
                                widget.userRideRequestDetails!.originLatLng!,
                                widget.userRideRequestDetails!.destinationLatLng!,
                                darkTheme,
                              );
                            }

                            if (mounted) Navigator.pop(context);
                          }
                          else if (rideRequestStatus == "arrived") {
                            setState(() {
                              rideRequestStatus = "onTrip";
                              buttonTitle = "End Trip";
                              buttonColor = Colors.red;
                            });

                            await FirebaseDatabase.instance
                                .ref()
                                .child("All Ride Requests")
                                .child(widget.userRideRequestDetails!.rideRequestId!)
                                .child("status")
                                .set(rideRequestStatus);
                          }
                          else if (rideRequestStatus == "onTrip") {
                            endTripNow();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(
                          Icons.directions_car,
                          color: darkTheme ? Colors.black : Colors.white,
                          size: 25,
                        ),
                        label: Text(
                          buttonTitle,
                          style: TextStyle(
                            color: darkTheme ? Colors.black : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}