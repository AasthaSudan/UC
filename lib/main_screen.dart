import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  LatLng ? pickLocation;
  loc.Location location=loc.location();
  String? _address;

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> scaffoldState= GlobalKey<ScaffoldState>();

  double searchLocationContainerHeight = 220;
  double waitingResponsefromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;

  Position? userCurrentPosition;
  var geoLocation = Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;

  List<LatLng> pLineCoordinatedList = [];
  Set<Polyline> polylineSet={};
  Set<Marker> markerSet={};
  Set<Circle> circleSet={}''
  // String userName="";
  // String userEmail="";

  bool openNavigationDrawer=true;
  bool activeNearbyDriverKeysLoaded=false;
  BitmapDescriptor? activeNearbyIcon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text("Main Screen"),
      // ),
      // body: Center(
      //   child: Text(
      //     "Hello Trippo!",
      //     style: TextStyle(fontSize: 24),
      //   ),
      // ),
    );
  }
}
