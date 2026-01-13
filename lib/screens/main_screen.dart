import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../info/app_info.dart';
import '../models/directions.dart';
import '../assistants/assistant_methods.dart';
import 'search_places_screen.dart';
import '../widgets/openroute_service.dart';
import 'profile_screen.dart';
import 'precise_pickup_location.dart';
import '../global/global.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/active_nearby_available_drivers.dart';
import '../assistants/geofire_assistant.dart';
import '../widgets/pay_fare_amount_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _makePhoneCall(String phoneNumber) async {
  final Uri url = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch $url';
  }
}

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

  String selectedVehicleType = "";
  String driverRideStatus = "Driver is coming";
  StreamSubscription<DatabaseEvent>? tripRideRequestInfoStreamSubscription;

  String userRideRequestStatus = "";

  List<ActiveNearbyAvailableDrivers> onlineNearByAvailableDriversList = [];

  double searchLocationContainerHeight = 0;
  double waitingResponsefromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;
  double suggestedRidesContainerHeight = 0;
  double bottomPaddingOfMap = 0;
  double searchingForDriverContainerHeight = 0;

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return text.substring(0, maxLength) + "...";
  }

  @override
  void dispose() {
    _debounce?.cancel();
    tripRideRequestInfoStreamSubscription?.cancel();
    super.dispose();
  }

  void updateDriversLocationAtRealTime(LatLng driverCurrentPositionLatLng) async {
    if (userRideRequestStatus == "accepted") {
      if (mounted) {
        setState(() {
          driverRideStatus = "Driver is coming";
        });
      }

      var pickupLocation = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
      if (pickupLocation == null) return;

      var originLatLng = LatLng(
        pickupLocation.locationLatitude!,
        pickupLocation.locationLongitude!,
      );

      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        driverCurrentPositionLatLng,
        originLatLng,
      );

      tripDirectionDetailsInfo = directionDetailsInfo;

      if (directionDetailsInfo != null && mounted) {
        setState(() {
          driverRideStatus = "Driver is coming - ${directionDetailsInfo.duration_text}";
        });
      }
    }
  }

  void updateReachingTimeToUserDropOffLocation(LatLng driverCurrentPositionLatLng) async {
    if (userRideRequestStatus == "onTrip") {
      if (mounted) {
        setState(() {
          driverRideStatus = "Going to destination";
        });
      }

      var dropOffLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;
      if (dropOffLocation == null) return;

      var dropOffLatLng = LatLng(
        dropOffLocation.locationLatitude!,
        dropOffLocation.locationLongitude!,
      );

      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        driverCurrentPositionLatLng,
        dropOffLatLng,
      );

      if (directionDetailsInfo != null && mounted) {
        setState(() {
          driverRideStatus = "Going to destination - ${directionDetailsInfo.duration_text}";
        });
      }
    }
  }

  void searchNearestOnlineDrivers(String selectedVehicleType) async {
    if (onlineNearByAvailableDriversList.isEmpty) {
      referenceRideRequest?.remove();

      if (mounted) {
        setState(() {
          polylinePoints.clear();
          markers.clear();
          circles.clear();
          suggestedRidesContainerHeight = 0;
          bottomPaddingOfMap = 0;
        });
      }

      Fluttertoast.showToast(
        msg: "No drivers available nearby. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    if (referenceRideRequest == null) {
      print("Error: referenceRideRequest is null");
      Fluttertoast.showToast(
        msg: "Error: Please try requesting a ride again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    if (mounted) {
      setState(() {
        waitingResponsefromDriverContainerHeight = 220;
        bottomPaddingOfMap = 220;
      });
    }

    print("Searching for nearest $selectedVehicleType drivers...");

    await retrieveOnlineDriversInformation(onlineNearByAvailableDriversList);

    print("Driver List: " + driversList.toString());

    for (int i = 0; i < driversList.length; i++) {
      if (driversList[i]["car_details"] == selectedVehicleType) {
        if (referenceRideRequest?.key != null) {
          AssistantMethods.sendNotificationToDriverNow(
              driversList[i]["token"],
              referenceRideRequest!.key!,
              context
          );
        }
        break;
      }
    }

    Fluttertoast.showToast(msg: "Notification sent successfully");

    showSearchingForDriversContainer();

    FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(referenceRideRequest!.key!)
        .child("driverId")
        .onValue
        .listen((eventRideRequestSnapshot) {
      print("EventSnapshot: ${eventRideRequestSnapshot.snapshot.value}");
      if (eventRideRequestSnapshot.snapshot.value != null) {
        if (eventRideRequestSnapshot.snapshot.value != "waiting") {
          showUIForDriverFound();
        }
      }
    });
  }

  void showUIForDriverFound() {
    if (mounted) {
      setState(() {
        waitingResponsefromDriverContainerHeight = 0;
        searchLocationContainerHeight = 0;
        assignedDriverInfoContainerHeight = 220;
        suggestedRidesContainerHeight = 0;
        bottomPaddingOfMap = 220;
      });
    }
  }

  void showSearchingForDriversContainer() {
    if (mounted) {
      setState(() {
        searchingForDriverContainerHeight = 220;
        bottomPaddingOfMap = 220;
      });
    }
  }

  void saveRideRequestInformation(String selectedVehicleType) {
    if (userModelCurrentInfo == null) {
      print("Error: User information is null");
      Fluttertoast.showToast(
        msg: "Error: User information not available. Please login again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    if (userModelCurrentInfo!.name == null || userModelCurrentInfo!.phone == null) {
      print("Error: User name or phone is null");
      Fluttertoast.showToast(
        msg: "Error: User profile incomplete. Please update your profile.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    var originLocation = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    if (originLocation == null || destinationLocation == null) {
      print("Error: Origin or destination location is null");
      Fluttertoast.showToast(
        msg: "Please select both pickup and drop-off locations",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    referenceRideRequest = FirebaseDatabase.instance.ref().child("All Ride Requests").push();

    Map originLocationMap = {
      "latitude": originLocation.locationLatitude.toString(),
      "longitude": originLocation.locationLongitude.toString(),
    };

    Map destinationLocationMap = {
      "latitude": destinationLocation.locationLatitude.toString(),
      "longitude": destinationLocation.locationLongitude.toString(),
    };

    Map userInformationMap = {
      "origin": originLocationMap,
      "destination": destinationLocationMap,
      "time": DateTime.now().toString(),
      "userName": firebaseAuth.currentUser?.displayName ?? "User",
      "userPhone": firebaseAuth.currentUser?.phoneNumber ?? "Unknown",
      "originAddress": originLocation.locationName ?? "Unknown",
      "destinationAddress": destinationLocation.locationName ?? "Unknown",
      "driverId": "waiting",
    };

    referenceRideRequest!.set(userInformationMap);

    tripRideRequestInfoStreamSubscription = referenceRideRequest!.onValue.listen((eventSnap) async {
      if (eventSnap.snapshot.value == null) {
        return;
      }

      if ((eventSnap.snapshot.value as Map)["car_details"] != null) {
        if (mounted) {
          setState(() {
            driverCarDetails = (eventSnap.snapshot.value as Map)["car_details"].toString();
          });
        }
      }

      if ((eventSnap.snapshot.value as Map)["driverName"] != null) {
        if (mounted) {
          setState(() {
            driverName = (eventSnap.snapshot.value as Map)["driverName"].toString();
          });
        }
      }

      if ((eventSnap.snapshot.value as Map)["driverPhone"] != null) {
        if (mounted) {
          setState(() {
            driverPhone = (eventSnap.snapshot.value as Map)["driverPhone"].toString();
          });
        }
      }

      if ((eventSnap.snapshot.value as Map)["driverRatings"] != null) {
        if (mounted) {
          setState(() {
            driverRatings = (eventSnap.snapshot.value as Map)["driverRatings"].toString();
          });
        }
      }

      if ((eventSnap.snapshot.value as Map)["status"] != null) {
        if (mounted) {
          setState(() {
            userRideRequestStatus = (eventSnap.snapshot.value as Map)["status"].toString();
          });
        }
      }

      if ((eventSnap.snapshot.value as Map)["driver_location"] != null) {
        double driverCurrentPositionLat = double.parse((eventSnap.snapshot.value as Map)["driver_location"]["latitude"].toString());
        double driverCurrentPositionLng = double.parse((eventSnap.snapshot.value as Map)["driver_location"]["longitude"].toString());

        LatLng driverCurrentPositionLatLng = LatLng(driverCurrentPositionLat, driverCurrentPositionLng);

        if (userRideRequestStatus == "accepted") {
          updateDriversLocationAtRealTime(driverCurrentPositionLatLng);
        }

        if (userRideRequestStatus == "arrived") {
          if (mounted) {
            setState(() {
              driverRideStatus = "Driver has arrived";
            });
          }
        }

        if (userRideRequestStatus == "onTrip") {
          updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng);
        }

        if (userRideRequestStatus == "ended") {
          if ((eventSnap.snapshot.value as Map)["fareAmount"] != null) {
            double fareAmount = double.parse((eventSnap.snapshot.value as Map)["fareAmount"].toString());

            if (mounted) {
              var response = await showDialog(
                context: context,
                builder: (BuildContext context) => PayFareAmountDialog(
                  fareAmount: fareAmount,
                ),
              );

              if (response == "cashPaid") {
                if ((eventSnap.snapshot.value as Map)["driverId"] != null) {
                  String driverId = (eventSnap.snapshot.value as Map)["driverId"].toString();

                  referenceRideRequest!.onDisconnect();
                  tripRideRequestInfoStreamSubscription!.cancel();
                }
              }
            }
          }
        }
      }
    });

    onlineNearByAvailableDriversList = GeoFireAssistant.activeNearbyAvailableDriversList;
    searchNearestOnlineDrivers(selectedVehicleType);
  }

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
  }

  void showSuggestedRidesContainer() {
    if (mounted) {
      setState(() {
        suggestedRidesContainerHeight = 400;
        bottomPaddingOfMap = 400;
      });
    }
  }

  void checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }

    await locateUserPosition();
  }

  Future<void> locateUserPosition() async {
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
        if (mounted) {
          setState(() {
            pickLocation = _initialLocation;
          });
        }
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("GPS outside India. Using New Delhi as default."),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          userCurrentPosition = cPosition;
          pickLocation = LatLng(cPosition.latitude, cPosition.longitude);
        });
      }

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
      if (mounted) {
        setState(() {
          pickLocation = _initialLocation;
        });
      }
      mapController.move(_initialLocation, 5.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not get GPS location. Using default."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> getAddressFromLatLng() async {
    if (pickLocation == null || _isLoadingAddress) return;

    _isLoadingAddress = true;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pickLocation!.latitude,
        pickLocation!.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
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

  Future<void> retrieveOnlineDriversInformation(List<ActiveNearbyAvailableDrivers> onlineNearByAvailableDriversList) async {
    driversList.clear();
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("Drivers");

    for (int i = 0; i < onlineNearByAvailableDriversList.length; i++) {
      await ref.child(onlineNearByAvailableDriversList[i].driverId!).once().then((dataSnapshot) {
        var driverKeyInfo = dataSnapshot.snapshot.value;

        driversList.add(driverKeyInfo);
        print("driver key info - " + driversList.toString());
      });
    }
  }

  Future<void> drawPolyLineFromOriginToDestination(bool darkTheme) async {
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
      builder: (BuildContext context) => const Center(
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

        if (mounted) {
          setState(() {
            polylinePoints = routePoints;

            markers = [
              Marker(
                point: originLatLng,
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 45,
                ),
              ),
              Marker(
                point: destinationLatLng,
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 45,
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
        }

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
              padding: const EdgeInsets.all(80),
            ),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Distance: ${directionDetails.distance_text} • Duration: ${directionDetails.duration_text}',
                style: const TextStyle(fontSize: 16),
              ),
              duration: const Duration(seconds: 5),
              backgroundColor: darkTheme ? Colors.amber.shade700 : Colors.blue,
            ),
          );
        }
      } else {
        print("No direction details received");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find route'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      print("Error drawing route: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDrawer(bool darkTheme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
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
          ListTile(
            leading: Icon(
              Icons.person,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            title: const Text("Profile"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.history,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            title: const Text("Ride History"),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ride History - Coming Soon")),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.payment,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            title: const Text("Payment Methods"),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Payment Methods - Coming Soon")),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.help_outline,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            title: const Text("Help & Support"),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Help & Support - Coming Soon")),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            title: const Text("About"),
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
                children: const [
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
                    urlTemplate: 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.project_1',
                  ),
                if (polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 5.0,
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      borderStrokeWidth: 2.0,
                      borderColor: darkTheme ? Colors.amber.shade700 : Colors.blue.shade700,
                    ),
                  ],
                ),
              if (circles.isNotEmpty)
                CircleLayer(circles: circles),
              if (markers.isNotEmpty)
                MarkerLayer(markers: markers),
              ],
            ),

              if (pickLocation != null && markers.isEmpty)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: const Offset(0, -25),
                      child: Icon(
                        Icons.location_on,
                        size: 50,
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      ),
                    ),
                  ),
                ),


            Positioned(
              top: 30,
              left: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                  ),
                  onPressed: () {
                    scaffoldState.currentState?.openDrawer();
                  },
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: darkTheme ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(10),
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
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: darkTheme ? Colors.grey.shade900 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
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
                                                ? _truncateText(Provider.of<AppInfo>(context).userPickUpLocation!.locationName ?? "Not Getting Address", 40)
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
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
                                                ? _truncateText(Provider.of<AppInfo>(context).userDropOffLocation!.locationName ?? "Where to?", 40)
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
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PrecisePickUpScreen(),
                                  ),
                                );
                              },
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Change Pick up",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black : Colors.white,
                                  ),
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
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (Provider.of<AppInfo>(context, listen: false).userPickUpLocation != null &&
                                    Provider.of<AppInfo>(context, listen: false).userDropOffLocation != null) {
                                  showSuggestedRidesContainer();
                                } else {
                                  Fluttertoast.showToast(
                                    msg: "Please select both pickup and drop-off locations",
                                  );
                                }
                              },
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Show Fare",
                                  style: TextStyle(
                                    color: darkTheme ? Colors.black : Colors.white,
                                  ),
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: suggestedRidesContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              Provider.of<AppInfo>(context, listen: false).userPickUpLocation != null
                                  ? _truncateText(Provider.of<AppInfo>(context, listen: false).userPickUpLocation!.locationName ?? "Not Getting Address", 35)
                                  : "Not Getting Address",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              Provider.of<AppInfo>(context, listen: false).userDropOffLocation != null
                                  ? _truncateText(Provider.of<AppInfo>(context, listen: false).userDropOffLocation!.locationName ?? "Where to?", 35)
                                  : "Where to?",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "SUGGESTED RIDES",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedVehicleType = "Car";
                              });
                            },
                            child: Container(
                              width: 110,
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "Car"
                                    ? (darkTheme ? Colors.amber.shade400 : Colors.blue)
                                    : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      "assets/images/img_4.png",
                                      scale: 2.5,
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "Car",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: selectedVehicleType == "Car"
                                            ? (darkTheme ? Colors.black : Colors.white)
                                            : (darkTheme ? Colors.white : Colors.black),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      tripDirectionDetailsInfo != null
                                          ? "₹${((AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) * 2) * 107).toStringAsFixed(0)}"
                                          : "null",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedVehicleType = "CNG";
                              });
                            },
                            child: Container(
                              width: 110,
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "CNG"
                                    ? (darkTheme ? Colors.amber.shade400 : Colors.blue)
                                    : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      "assets/images/img_5.png",
                                      scale: 2.5,
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "CNG",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: selectedVehicleType == "CNG"
                                            ? (darkTheme ? Colors.black : Colors.white)
                                            : (darkTheme ? Colors.white : Colors.black),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      tripDirectionDetailsInfo != null
                                          ? "₹${((AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) * 1.5) * 107).toStringAsFixed(0)}"
                                          : "null",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedVehicleType = "Bike";
                              });
                            },
                            child: Container(
                              width: 110,
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "Bike"
                                    ? (darkTheme ? Colors.amber.shade400 : Colors.blue)
                                    : (darkTheme ? Colors.black54 : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      "assets/images/img_6.png",
                                      scale: 2.5,
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "Bike",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: selectedVehicleType == "Bike"
                                            ? (darkTheme ? Colors.black : Colors.white)
                                            : (darkTheme ? Colors.white : Colors.black),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      tripDirectionDetailsInfo != null
                                          ? "₹${((AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) * 0.8) * 107).toStringAsFixed(0)}"
                                          : "null",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          if (selectedVehicleType != "") {
                            saveRideRequestInformation(selectedVehicleType);
                          } else {
                            Fluttertoast.showToast(
                              msg: "Please select a vehicle type",
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "Request Ride",
                              style: TextStyle(
                                color: darkTheme ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: searchingForDriverContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LinearProgressIndicator(
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        "Please wait...",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        if (referenceRideRequest != null) {
                          referenceRideRequest!.remove();
                        }
                        setState(() {
                          searchingForDriverContainerHeight = 0;
                          suggestedRidesContainerHeight = 0;
                        });
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: darkTheme ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Icon(Icons.close, size: 25),
                      ),
                    ),
                    SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      child: Text(
                        "Cancel",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
             ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: assignedDriverInfoContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text(
                        driverRideStatus,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 5),

                      Divider(
                        thickness: 1,
                        color: darkTheme ? Colors.grey : Colors.grey[300],
                      ),

                      const SizedBox(height: 5),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: darkTheme
                                      ? Colors.amber.shade400
                                      : Colors.lightBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: darkTheme ? Colors.black : Colors.white,
                                ),
                              ),

                              const SizedBox(width: 10),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    "4.5 ⭐",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Image.asset(
                                "assets/images/img_7.png",
                                scale: 3,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                driverCarDetails,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      ElevatedButton.icon(
                        onPressed: () {
                          _makePhoneCall(driverPhone);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          darkTheme ? Colors.amber.shade400 : Colors.blue,
                        ),
                        icon: Icon(
                          Icons.phone,
                          color: darkTheme ? Colors.black : Colors.white,
                        ),
                        label: Text(
                          "Call Driver",
                          style: TextStyle(
                            color: darkTheme ? Colors.black : Colors.white,
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
      ),
    );
  }
}