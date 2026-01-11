import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import '../models/user_ride_request_info.dart';
import '../assistants/assistant_methods.dart';
import '../info/directions_details_info.dart';

class NewRideScreen extends StatefulWidget {
  final UserRideRequestInfo? userRideRequestDetails;

  const NewRideScreen({super.key, this.userRideRequestDetails});

  @override
  State<NewRideScreen> createState() => _NewRideScreenState();
}

class _NewRideScreenState extends State<NewRideScreen> {
  LatLng? pickLocation;
  final MapController mapController = MapController();

  static const LatLng _initialLocation = LatLng(28.6139, 77.2090);
  static const LatLng _southWestBound = LatLng(6.5546, 68.1113);
  static const LatLng _northEastBound = LatLng(35.6745, 97.3953);

  List<Marker> markers = [];
  List<CircleMarker> circleMarkers = [];
  List<Polyline> polylines = [];
  List<LatLng> polylinePositionCoordinates = [];

  double mapPadding = 0;
  Position? currentPosition;
  LatLng? driverCurrentLocation;

  String rideRequestStatus = "accepted";
  String durationFromOriginToDestination = "";
  bool isRequestingDirection = false;

  StreamSubscription<DatabaseEvent>? streamSubscriptionDriverLivePosition;

  @override
  void initState() {
    super.initState();
    _initializeRide();
  }

  @override
  void dispose() {
    streamSubscriptionDriverLivePosition?.cancel();
    super.dispose();
  }

  Future<void> _initializeRide() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted && widget.userRideRequestDetails != null) {
        setState(() {
          mapPadding = 250;
        });

        var userPickUpLatLng = widget.userRideRequestDetails!.originLatLng!;
        var userDropOffLatLng = widget.userRideRequestDetails!.destinationLatLng!;

        mapController.move(userPickUpLatLng, 15.0);

        // Add passenger pickup marker (blue)
        markers.add(
          Marker(
            key: Key("pickupMarker"),
            point: userPickUpLatLng,
            width: 80,
            height: 80,
            child: Icon(
              Icons.person_pin_circle,
              color: Colors.blue,
              size: 50,
            ),
          ),
        );

        // Add passenger destination marker (orange)
        markers.add(
          Marker(
            key: Key("destinationMarker"),
            point: userDropOffLatLng,
            width: 80,
            height: 80,
            child: Icon(
              Icons.flag,
              color: Colors.orange,
              size: 50,
            ),
          ),
        );

        // Add pickup circle
        circleMarkers.add(
          CircleMarker(
            point: userPickUpLatLng,
            color: Colors.blueAccent.withOpacity(0.3),
            borderColor: Colors.blue,
            borderStrokeWidth: 3,
            radius: 12,
          ),
        );

        // Listen to driver location updates
        getDriverLocationUpdatesAtRealTime();
      }
    } catch (e) {
      print('Error initializing ride: $e');
      if (mounted) {
        Fluttertoast.showToast(msg: "Error: $e");
      }
    }
  }

  void getDriverLocationUpdatesAtRealTime() {
    if (widget.userRideRequestDetails?.rideRequestId == null) return;

    DatabaseReference driverLocationRef = FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(widget.userRideRequestDetails!.rideRequestId!)
        .child("driverLocation");

    streamSubscriptionDriverLivePosition = driverLocationRef.onValue.listen((event) async {
      if (event.snapshot.value != null && mounted) {
        Map<dynamic, dynamic> locationData = event.snapshot.value as Map<dynamic, dynamic>;

        double driverLat = double.parse(locationData["latitude"].toString());
        double driverLng = double.parse(locationData["longitude"].toString());

        LatLng latLngLiveDriverPosition = LatLng(driverLat, driverLng);
        driverCurrentLocation = latLngLiveDriverPosition;

        setState(() {
          // Remove old driver marker
          markers.removeWhere((marker) =>
          marker.key == Key("driverMarker") || marker.key == Key("liveDriver"));

          // Add new driver marker (green taxi)
          markers.add(
            Marker(
              key: Key("liveDriver"),
              point: latLngLiveDriverPosition,
              width: 80,
              height: 80,
              child: Icon(
                Icons.local_taxi,
                color: Colors.green,
                size: 50,
              ),
            ),
          );

          // Update driver circle
          circleMarkers.removeWhere((circle) =>
          circle.borderColor == Colors.green);

          circleMarkers.add(
            CircleMarker(
              point: latLngLiveDriverPosition,
              color: Colors.greenAccent.withOpacity(0.3),
              borderColor: Colors.green,
              borderStrokeWidth: 3,
              radius: 12,
            ),
          );
        });

        // Draw route from driver to passenger
        await drawPolyLineFromOriginToDestination(
          latLngLiveDriverPosition,
          widget.userRideRequestDetails!.originLatLng!,
          MediaQuery.of(context).platformBrightness == Brightness.dark,
        );

        // Update duration
        updateDriversLocationAtRealTime(latLngLiveDriverPosition);
      }
    });
  }

  Future<void> drawPolyLineFromOriginToDestination(
      LatLng driverCurrentLatLng,
      LatLng userPickUpLatLng,
      bool darkTheme,
      ) async {
    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
      driverCurrentLatLng,
      userPickUpLatLng,
    );

    // Fix: Check if directionDetailsInfo is not null AND e_points is not null
    if (directionDetailsInfo != null && directionDetailsInfo.e_points != null && mounted) {
      polylinePositionCoordinates = _decodePolyline(directionDetailsInfo.e_points!);

      setState(() {
        polylines.clear();
        polylines.add(
          Polyline(
            points: polylinePositionCoordinates,
            color: darkTheme ? Colors.amber.shade400 : Colors.amber,
            strokeWidth: 5.0,
          ),
        );
      });

      try {
        mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds(driverCurrentLatLng, userPickUpLatLng),
            padding: EdgeInsets.all(65),
          ),
        );
      } catch (e) {
        print('Error fitting camera: $e');
      }
    }
  }

  Future<void> updateDriversLocationAtRealTime(LatLng driverCurrentPositionLatLng) async {
    if (isRequestingDirection == false) {
      isRequestingDirection = true;

      var originLatLng = driverCurrentPositionLatLng;
      var destinationLatLng = widget.userRideRequestDetails!.originLatLng!;

      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        originLatLng,
        destinationLatLng,
      );

      if (directionDetailsInfo != null && mounted) {
        setState(() {
          durationFromOriginToDestination = directionDetailsInfo.duration_text ?? "";
        });
      }

      isRequestingDirection = false;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: mapPadding),
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: pickLocation ?? _initialLocation,
                initialZoom: 15.0,
                minZoom: 5.0,
                maxZoom: 19.0,
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(_southWestBound, _northEastBound),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: darkTheme
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'
                      : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                  userAgentPackageName: 'com.yourcompany.rideapp',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  maxZoom: 19,
                ),
                PolylineLayer(polylines: polylines),
                CircleLayer(circles: circleMarkers),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        durationFromOriginToDestination.isEmpty
                            ? "Waiting for driver..."
                            : durationFromOriginToDestination,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: darkTheme ? Colors.amber.shade400 : Colors.black,
                        ),
                      ),
                      SizedBox(height: 15),
                      Divider(
                        thickness: 1,
                        color: darkTheme ? Colors.amber.shade400 : Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.userRideRequestDetails?.userName ?? "Driver",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: darkTheme ? Colors.amber.shade400 : Colors.black,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // Add phone call functionality
                            },
                            icon: Icon(
                              Icons.call,
                              color: darkTheme ? Colors.amber.shade400 : Colors.green,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.trip_origin,
                            color: Colors.red,
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.userRideRequestDetails?.originAddress ?? "Your Location",
                              style: TextStyle(
                                fontSize: 16,
                                color: darkTheme ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.orange,
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.userRideRequestDetails?.destinationAddress ?? "Destination",
                              style: TextStyle(
                                fontSize: 16,
                                color: darkTheme ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}