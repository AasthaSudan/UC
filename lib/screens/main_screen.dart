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
import 'search_places_screen.dart';
import '../widgets/openroute_service.dart';
import 'profile_screen.dart';
import 'precise_pickup_location.dart';
import '../global/global.dart';

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

    await locateUserPosition();
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("GPS outside India. Using New Delhi as default."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
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

      String humanReadableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(
        cPosition,
        context,
      );
      print("This is our address = $humanReadableAddress");
    } catch (e) {
      print("Error getting location: $e");
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      var directionDetails = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        originLatLng,
        destinationLatLng,
      );

      Navigator.pop(context);

      if (directionDetails != null && directionDetails.e_points != null) {
        print("Got direction details, decoding polyline...");

        var routePoints = OpenRouteService().decodePolyline(directionDetails.e_points!);

        print("Decoded ${routePoints.length} route points");

        setState(() {
          polylinePoints = routePoints;

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
      Navigator.pop(context);
      print("Error drawing route: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDrawer(bool darkTheme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            accountName: Text(
              userModelCurrentInfo?.name ?? userName,
              style: TextStyle(
                color: darkTheme ? Colors.black : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              userModelCurrentInfo?.email ?? userEmail,
              style: TextStyle(
                color: darkTheme ? Colors.black87 : Colors.white70,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: darkTheme ? Colors.black : Colors.white,
              child: Icon(
                Icons.person,
                size: 50,
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
              ),
            ),
          ),

          // Menu Items
          ListTile(
            leading: Icon(
              Icons.person,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            title: Text("Profile"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),

          ListTile(
            leading: Icon(
              Icons.history,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            title: Text("Ride History"),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Ride History - Coming Soon")),
              );
            },
          ),

          ListTile(
            leading: Icon(
              Icons.payment,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            title: Text("Payment Methods"),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Payment Methods - Coming Soon")),
              );
            },
          ),

          ListTile(
            leading: Icon(
              Icons.help_outline,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            title: Text("Help & Support"),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Help & Support - Coming Soon")),
              );
            },
          ),

          Divider(),

          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            title: Text("About"),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: "Trippo",
                applicationVersion: "1.0.0",
                applicationIcon: Icon(
                  Icons.local_taxi,
                  size: 50,
                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                ),
                children: [
                  Text("A ride-sharing app for India"),
                ],
              );
            },
          ),
        ],
      ),
    );
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
        drawer: _buildDrawer(darkTheme),
        body: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: pickLocation ?? _initialLocation,
                initialZoom: 5.0,
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
                    _debounce = Timer(const Duration(milliseconds: 1000), () {
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

            // Drawer Icon Button
            Positioned(
              top: 30,
              left: 10,
              child: IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  scaffoldState.currentState?.openDrawer(); // Open drawer
                },
              ),
            ),

            // Your existing UI here
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
                          // "From" and "To" pickup/drop locations UI
                          Container(
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.grey.shade900 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(5),
                                  child: GestureDetector(
                                    onTap: () {
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

                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PrecisePickUpScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Change Pick up",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black : Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              SizedBox(width: 10),

                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PrecisePickUpScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Request a ride",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black : Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}