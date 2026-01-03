import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'app_info.dart';
import 'directions.dart';
import 'assistant_methods.dart';
import 'search_places_screen.dart';
import 'openroute_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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

  List<LatLng> polylinePoints = [];
  List<Marker> markers = [];
  List<CircleMarker> circles = [];

  bool openNavigationDrawer = true;
  Timer? _debounce;
  bool _isLoadingAddress = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
  }

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }

    // Automatically locate user on start
    await locateUserPosition();
  }

  locateUserPosition() async {
    try {
      Position cPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Check if location is within India bounds
      bool isInIndia = cPosition.latitude >= _southWestBound.latitude &&
          cPosition.latitude <= _northEastBound.latitude &&
          cPosition.longitude >= _southWestBound.longitude &&
          cPosition.longitude <= _northEastBound.longitude;

      if (!isInIndia) {
        print("GPS location is outside India. Using default location (New Delhi).");
        // Use default India location
        setState(() {
          pickLocation = _initialLocation;
        });
        mapController.move(_initialLocation, 12.0);

        // Get address for New Delhi
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("GPS outside India. Using New Delhi as default."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Location is in India
      setState(() {
        userCurrentPosition = cPosition;
        pickLocation = LatLng(cPosition.latitude, cPosition.longitude);
      });

      // Animate to user location with appropriate zoom
      mapController.move(
        LatLng(cPosition.latitude, cPosition.longitude),
        15.0, // Street level zoom
      );

      String humanReadableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(
        cPosition,
        context,
      );
      print("This is our address = $humanReadableAddress");
    } catch (e) {
      print("Error getting location: $e");
      // If GPS fails, show default India location
      setState(() {
        pickLocation = _initialLocation;
      });
      mapController.move(_initialLocation, 5.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not get GPS location. Using default."),
          backgroundColor: Colors.red,
        ),
      );
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
          Directions userPickAddress = Directions();
          userPickAddress.locationLatitude = pickLocation!.latitude;
          userPickAddress.locationLongitude = pickLocation!.longitude;
          userPickAddress.locationName = address;

          Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickAddress);
        });

        print("Updated pickup address: $address");
      }
    } catch (e) {
      print("Error getting address: $e");
    } finally {
      _isLoadingAddress = false;
    }
  }

  drawPolyLineFromOriginToDestination(bool darkTheme) async {
    var originPosition = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    if (originPosition == null || destinationPosition == null) {
      print("Origin or destination is null");
      return;
    }

    var originLatLng = LatLng(originPosition.locationLatitude!, originPosition.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition.locationLatitude!, destinationPosition.locationLongitude!);

    print("Origin: ${originLatLng.latitude}, ${originLatLng.longitude}");
    print("Destination: ${destinationLatLng.latitude}, ${destinationLatLng.longitude}");

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get route from OpenRouteService
      var directionDetails = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        originLatLng,
        destinationLatLng,
      );

      Navigator.pop(context); // Close loading dialog

      if (directionDetails != null && directionDetails.e_points != null) {
        print("Got direction details, decoding polyline...");

        // Decode polyline
        var routePoints = OpenRouteService().decodePolyline(directionDetails.e_points!);

        print("Decoded ${routePoints.length} route points");

        setState(() {
          polylinePoints = routePoints;

          // Add markers for origin and destination
          markers = [
            Marker(
              point: originLatLng,
              width: 80,
              height: 80,
              child: Column(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 45,
                  ),
                ],
              ),
            ),
            Marker(
              point: destinationLatLng,
              width: 80,
              height: 80,
              child: Column(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 45,
                  ),
                ],
              ),
            ),
          ];

          // Add circles around markers
          circles = [
            CircleMarker(
              point: originLatLng,
              radius: 30,
              useRadiusInMeter: false,
              color: Colors.green.withOpacity(0.2),
              borderColor: Colors.green,
              borderStrokeWidth: 3,
            ),
            CircleMarker(
              point: destinationLatLng,
              radius: 30,
              useRadiusInMeter: false,
              color: Colors.red.withOpacity(0.2),
              borderColor: Colors.red,
              borderStrokeWidth: 3,
            ),
          ];
        });

        // Fit bounds to show entire route
        if (routePoints.isNotEmpty) {
          double minLat = routePoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
          double maxLat = routePoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
          double minLng = routePoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
          double maxLng = routePoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

          LatLngBounds bounds = LatLngBounds(
            LatLng(minLat, minLng),
            LatLng(maxLat, maxLng),
          );

          mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: EdgeInsets.all(80),
            ),
          );
        }

        // Show route info
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Distance: ${directionDetails.distance_text} • Duration: ${directionDetails.duration_text}',
              style: TextStyle(fontSize: 16),
            ),
            duration: Duration(seconds: 5),
            backgroundColor: darkTheme ? Colors.amber.shade700 : Colors.blue,
          ),
        );
      } else {
        print("No direction details received");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find route'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print("Error drawing route: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: scaffoldState,
        body: Stack(
          children: [
            // Flutter Map
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: pickLocation ?? _initialLocation,
                initialZoom: 5.0, // Zoom level to show whole India
                minZoom: 4.0, // Minimum zoom (can't zoom out too much)
                maxZoom: 18.0, // Maximum zoom (street level)
                // Restrict map to India boundaries
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
                  // Update pickup location when map is moved (debounced)
                  if (hasGesture && position.center != null) {
                    setState(() {
                      pickLocation = position.center;
                    });

                    // Debounce the address lookup
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 1000), () {
                      getAddressFromLatLng();
                    });
                  }
                },
              ),
              children: [
                // Tile Layer (OpenStreetMap)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.project_1',
                ),

                // Polyline Layer (ROUTE)
                if (polylinePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: polylinePoints,
                        strokeWidth: 6.0,
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                        borderStrokeWidth: 2.0,
                        borderColor: darkTheme ? Colors.amber.shade900 : Colors.blue.shade900,
                      ),
                    ],
                  ),

                // Circle Layer
                if (circles.isNotEmpty)
                  CircleLayer(circles: circles),

                // Marker Layer
                if (markers.isNotEmpty)
                  MarkerLayer(markers: markers),
              ],
            ),

            // Center Pin Image (Draggable pickup location indicator)
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 35.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      size: 45,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Move map to set pickup",
                        style: TextStyle(
                          color: darkTheme ? Colors.black : Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Container with Pickup/Dropoff
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: darkTheme ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.grey.shade900 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                // From Location
                                Padding(
                                  padding: EdgeInsets.all(5),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Allow user to change pickup location
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text("Change Pickup Location"),
                                          content: Text(
                                            "Move the map to your desired pickup location and the address will update automatically.",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text("OK"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                        ),
                                        SizedBox(width: 10),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "From",
                                                    style: TextStyle(
                                                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(width: 5),
                                                  Icon(
                                                    Icons.edit,
                                                    size: 14,
                                                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                Provider.of<AppInfo>(context).userPickUpLocation != null
                                                    ? (Provider.of<AppInfo>(context).userPickUpLocation!.locationName!.length > 30
                                                    ? Provider.of<AppInfo>(context).userPickUpLocation!.locationName!.substring(0, 30) + "..."
                                                    : Provider.of<AppInfo>(context).userPickUpLocation!.locationName!)
                                                    : "Not Getting Address",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: 5),
                                Divider(
                                  height: 1,
                                  thickness: 2,
                                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                ),
                                SizedBox(height: 5),

                                // To Location
                                Padding(
                                  padding: EdgeInsets.all(5),
                                  child: GestureDetector(
                                    onTap: () async {
                                      var responseFromSearchScreen = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SearchPlacesScreen(),
                                        ),
                                      );

                                      if (responseFromSearchScreen == "obtainDirectionResponse") {
                                        setState(() {
                                          openNavigationDrawer = false;
                                        });
                                        await drawPolyLineFromOriginToDestination(darkTheme);
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                        ),
                                        SizedBox(width: 10),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "To",
                                                style: TextStyle(
                                                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                Provider.of<AppInfo>(context).userDropOffLocation != null
                                                    ? (Provider.of<AppInfo>(context).userDropOffLocation!.locationName!.length > 30
                                                    ? Provider.of<AppInfo>(context).userDropOffLocation!.locationName!.substring(0, 30) + "..."
                                                    : Provider.of<AppInfo>(context).userDropOffLocation!.locationName!)
                                                    : "Where to?",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Control Buttons
            Positioned(
              right: 20,
              bottom: 350,
              child: Column(
                children: [
                  // Show All India Button
                  FloatingActionButton(
                    heroTag: "showIndia",
                    mini: true,
                    onPressed: () {
                      mapController.fitCamera(
                        CameraFit.bounds(
                          bounds: _indiaBounds,
                          padding: EdgeInsets.all(50),
                        ),
                      );
                    },
                    backgroundColor: Colors.orange,
                    child: Icon(
                      Icons.map,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(height: 10),
                  // My Location Button
                  FloatingActionButton(
                    heroTag: "myLocation",
                    onPressed: locateUserPosition,
                    backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    child: Icon(
                      Icons.my_location,
                      color: darkTheme ? Colors.black : Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Set Pickup Location Button
                  FloatingActionButton(
                    heroTag: "setPickup",
                    onPressed: () async {
                      if (pickLocation != null) {
                        // Update pickup location to current map center
                        await getAddressFromLatLng();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Pickup location updated!"),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
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
}