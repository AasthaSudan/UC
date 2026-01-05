import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import '../assistants/assistant_methods.dart';
import '../global/global.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const String _availableDriversNode = "availableDrivers";
  static const LatLng _initialLocation = LatLng(28.6139, 77.2090);

  LatLng? pickLocation;
  final MapController mapController = MapController();
  String statusText = "Now Offline";
  Color buttonColor = Colors.red;
  bool isDriverActive = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    streamSubscriptionPosition?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await checkIfLocationPermissionAllowed();
    await readCurrentDriverInfo();
  }

  Future<void> checkIfLocationPermissionAllowed() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await locateUserPosition();
    }
  }

  Future<void> locateUserPosition() async {
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
  }

  Future<void> makeDriverOnlineNow() async {
    setState(() => isLoading = true);

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    driverCurrentPosition = position;

    Geofire.initialize(_availableDriversNode);
    Geofire.setLocation(
      onlineDriverData.id!,
      position.latitude,
      position.longitude,
    );

    await FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(onlineDriverData.id!)
        .child("status")
        .set("online");

    getLocationLiveUpdates();

    setState(() {
      statusText = "Now Online";
      buttonColor = Colors.green;
      isDriverActive = true;
      isLoading = false;
    });
  }

  void getLocationLiveUpdates() {
    streamSubscriptionPosition =
        Geolocator.getPositionStream().listen((Position position) {
          if (!isDriverActive) return;

          driverCurrentPosition = position;

          Geofire.setLocation(
            onlineDriverData.id!,
            position.latitude,
            position.longitude,
          );

          mapController.move(
            LatLng(position.latitude, position.longitude),
            15,
          );
        });
  }

  Future<void> makeDriverOfflineNow() async {
    setState(() => isLoading = true);

    Geofire.removeLocation(onlineDriverData.id!);

    await FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(onlineDriverData.id!)
        .child("status")
        .set("offline");

    streamSubscriptionPosition?.cancel();

    setState(() {
      statusText = "Now Offline";
      buttonColor = Colors.red;
      isDriverActive = false;
      isLoading = false;
    });
  }

  Future<void> readCurrentDriverInfo() async {
    currentUser = firebaseAuth.currentUser;

    if (currentUser == null) return;

    final snap = await FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentUser!.uid)
        .get();

    if (!snap.exists) return;

    final data = snap.value as Map;

    onlineDriverData
      ..id = currentUser!.uid
      ..name = data["name"]
      ..email = data["email"]
      ..phone = data["phone"]
      ..address = data["address"]
      ..car_color = data["car_details"]["car_color"]
      ..car_model = data["car_details"]["car_model"]
      ..car_number = data["car_details"]["car_number"]
      ..car_type = data["car_details"]["car_type"];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: pickLocation ?? _initialLocation,
              initialZoom: 5,
              minZoom: 4,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: [
                  if (pickLocation != null)
                    Marker(
                      point: pickLocation!,
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.local_taxi,
                        color:
                        isDriverActive ? Colors.green : Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                  if (!isDriverActive) {
                    await makeDriverOnlineNow();
                  } else {
                    await makeDriverOfflineNow();
                  }
                },
                child: isLoading
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
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
      ),
    );
  }
}
