import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import '../info/app_info.dart';
import '../models/directions.dart';
import '../assistants/assistant_methods.dart';

class PrecisePickUpScreen extends StatefulWidget {
  const PrecisePickUpScreen({super.key});

  @override
  State<PrecisePickUpScreen> createState() => _PrecisePickUpScreenState();
}

class _PrecisePickUpScreenState extends State<PrecisePickUpScreen> {
  LatLng? pickLocation;
  String? _address;

  final MapController mapController = MapController();

  static const LatLng _initialLocation = LatLng(28.6139, 77.2090);

  static const LatLng _southWestBound = LatLng(6.5546, 68.1113);
  static const LatLng _northEastBound = LatLng(35.6745, 97.3953);
  static final LatLngBounds _indiaBounds = LatLngBounds(_southWestBound, _northEastBound);

  GlobalKey<ScaffoldState> scaffoldState = GlobalKey<ScaffoldState>();
  Position? userCurrentPosition;
  LocationPermission? _locationPermission;
  bool _isLoadingAddress = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Get current pickup location from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var currentPickup = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
      if (currentPickup != null) {
        setState(() {
          pickLocation = LatLng(currentPickup.locationLatitude!, currentPickup.locationLongitude!);
          _address = currentPickup.locationName;
        });
        mapController.move(pickLocation!, 15.0);
      } else {
        locateUserPosition();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  locateUserPosition() async {
    try {
      Position cPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      bool isInIndia = cPosition.latitude >= _southWestBound.latitude &&
          cPosition.latitude <= _northEastBound.latitude &&
          cPosition.longitude >= _southWestBound.longitude &&
          cPosition.longitude <= _northEastBound.longitude;

      if (!isInIndia) {
        print("GPS location is outside India. Using default location (New Delhi).");
        setState(() {
          pickLocation = _initialLocation;
        });
        mapController.move(_initialLocation, 12.0);

        Position newDelhiPosition = Position(
          latitude: _initialLocation.latitude,
          longitude: _initialLocation.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

        String humanReadableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(
          newDelhiPosition,
          context,
        );
        return;
      }

      setState(() {
        userCurrentPosition = cPosition;
        pickLocation = LatLng(cPosition.latitude, cPosition.longitude);
      });

      mapController.move(
        LatLng(cPosition.latitude, cPosition.longitude),
        15.0,
      );

      await getAddressFromLatLng();
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  getAddressFromLatLng() async {
    if (pickLocation == null || _isLoadingAddress) return;

    _isLoadingAddress = true;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pickLocation!.latitude,
        pickLocation!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

        setState(() {
          _address = address;
          Directions userPickAddress = Directions();
          userPickAddress.locationLatitude = pickLocation!.latitude;
          userPickAddress.locationLongitude = pickLocation!.longitude;
          userPickAddress.locationName = address;

          Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickAddress);
        });
      }
    } catch (e) {
      print("Error getting address: $e");
    } finally {
      _isLoadingAddress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: scaffoldState,
      appBar: AppBar(
        backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
        title: Text(
          "Set Precise Pickup Location",
          style: TextStyle(
            color: darkTheme ? Colors.black : Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: darkTheme ? Colors.black : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: pickLocation ?? _initialLocation,
              initialZoom: 15.0,
              minZoom: 4.0,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: _indiaBounds,
              ),
              onTap: (tapPosition, point) {
                setState(() {
                  pickLocation = point;
                });
                getAddressFromLatLng();
              },
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() {
                    pickLocation = position.center;
                  });

                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 800), () {
                    getAddressFromLatLng();
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.project_1',
              ),
            ],
          ),

          // Center pin
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35.0),
              child: Icon(
                Icons.location_on,
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                size: 50,
              ),
            ),
          ),

          // Address display at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: darkTheme ? Colors.black : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pickup Location",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _address ?? "Move map to select location...",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_address != null) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Pickup location updated!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Confirm Pickup Location",
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

          // My location button
          Positioned(
            right: 20,
            bottom: 200,
            child: FloatingActionButton(
              onPressed: locateUserPosition,
              backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
              child: Icon(
                Icons.my_location,
                color: darkTheme ? Colors.black : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}