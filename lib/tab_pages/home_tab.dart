import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../assistants/assistant_methods.dart';
import '../global/global.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_geofire/flutter_geofire.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {

  LatLng? pickLocation;
  final MapController mapController = MapController();

  static const LatLng _initialLocation = LatLng(28.6139, 77.2090);
  static final LatLngBounds _indiaBounds = LatLngBounds(
    LatLng(6.5546, 68.1113),
    LatLng(35.6745, 97.3953),
  );

  String statusText = "Now Offline";
  Color buttonColor = Colors.red;
  bool isDriverActive = false;

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
    readCurrentDriverInfo();
  }

  // ---------------- LOCATION ----------------

  Future<void> checkIfLocationPermissionAllowed() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) return;
    locateUserPosition();
  }

  Future<void> locateUserPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      driverCurrentPosition = position;
      pickLocation = LatLng(position.latitude, position.longitude);

      mapController.move(pickLocation!, 15);

      await AssistantMethods.searchAddressForGeographicCoordinates(
        position,
        context,
      );
    } catch (e) {
      pickLocation = _initialLocation;
      mapController.move(_initialLocation, 5);
    }
  }

  // ---------------- DRIVER ONLINE ----------------

  Future<void> makeDriverOnlineNow() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    driverCurrentPosition = position;

    Geofire.initialize("availableDrivers");
    Geofire.setLocation(
      onlineDriverData.id!,
      position.latitude,
      position.longitude,
    );

    getLocationLiveUpdates();
  }

  void getLocationLiveUpdates() {
    streamSubscriptionPosition =
        Geolocator.getPositionStream().listen((Position cPosition) {
          if (!isDriverActive) return;

          Geofire.setLocation(
            onlineDriverData.id!,
            cPosition.latitude,
            cPosition.longitude,
          );

          mapController.move(
            LatLng(cPosition.latitude, cPosition.longitude),
            15,
          );
        });
  }

  void makeDriverOfflineNow() {
    Geofire.removeLocation(onlineDriverData.id!);

    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(onlineDriverData.id!)
        .remove();

    streamSubscriptionPosition?.cancel();
  }

  // ---------------- DRIVER INFO ----------------

  void readCurrentDriverInfo() async {
    currentUser = firebaseAuth.currentUser;

    final snap = await FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentUser!.uid)
        .get();

    if (snap.exists) {
      final data = snap.value as Map;

      onlineDriverData
        ..id = data["id"]
        ..name = data["name"]
        ..email = data["email"]
        ..phone = data["phone"]
        ..address = data["address"]
        ..car_color = data["car_details"]["car_color"]
        ..car_model = data["car_details"]["car_model"]
        ..car_number = data["car_details"]["car_number"]
        ..car_type = data["car_details"]["car_type"];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: pickLocation ?? _initialLocation,
            initialZoom: 5,
            minZoom: 4,
            maxZoom: 18,
            cameraConstraint:
            CameraConstraint.contain(bounds: _indiaBounds),
          ),
          children: const [],
        ),

        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                if (!isDriverActive) {
                  makeDriverOnlineNow();
                  setState(() {
                    statusText = "Now Online";
                    buttonColor = Colors.green;
                    isDriverActive = true;
                  });
                } else {
                  makeDriverOfflineNow();
                  setState(() {
                    statusText = "Now Offline";
                    buttonColor = Colors.red;
                    isDriverActive = false;
                  });
                }
              },
              child: Text(
                statusText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
