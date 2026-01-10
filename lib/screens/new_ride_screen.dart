import 'package:flutter/material.dart';

class NewRideScreen extends StatefulWidget {
  const NewRideScreen({super.key});

  @override
  State<NewRideScreen> createState() => _NewRideScreenState();
}

class _NewRideScreenState extends State<NewRideScreen> {
  LatLng? pickLocation;
  String? _address;
  final MapController mapController = MapController();

  static const LatLng _initialLocation = LatLng(28.6139, 77.2090);
  static const LatLng _southWestBound = LatLng(6.5546, 68.1113);
  static const LatLng _northEastBound = LatLng(35.6745, 97.3953);
  static final LatLngBounds _indiaBounds = LatLngBounds(_southWestBound, _northEastBound);

  Set<Marker> markers = Set<Marker>();
  Set<Circle> circles = Set<Circle>();
  Set<Polyline> polyLines = Set<Polyline>();
  List<LatLng> polylinePoints = [];
  PolylinePoints polylinePoints = PolylinePoints();

  double mapPadding=0;
  BitmapDescriptor? carIcon;
  var geolocator = Geolocator();
  Position? currentPosition;

  String rideRequestStatus = "accepted";
  String durationFromOriginToDestination = "";
  bool isRequestingDirection = false;

  Future<void> drawPolyLineFromOriginToDestination(LatLng driverCurrentLatLng, LatLng userPickUpLatLng, bool darkTheme) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        message: "Please wait...",
      ),
    );

    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(driverCurrentLatLng, userPickUpLatLng);



    )





  @override
  Widget build(BuildContext context) {

    bool darkTheme=MediaQuery.of(context).platformBrightness==Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
          padding: EdgeInsets.only(bottom: mapPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            initialCameraPosition: CameraPosition(
              target: pickLocation ?? _initialLocation,
              zoom: 5.0,
                markers: markers,
              circles: circles,
              polyLines: polyLines,
              onMapCreated: (mapController){
                mapController.move(pickLocation ?? _initialLocation, 15.0);
              },

                setState(() {
                  mapPadding = 350;
                });

              var driverCurrentLatLng=LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
              var userPickUpLatLng=widget.userRideRequestDetails!.originLocation;
              var userDropOffLatLng=widget.userRideRequestDetails!.destinationLocation;

              drawPolyLineFromOriginToDestination(driverCurrentLatLng, userPickUpLatLng, darkTheme);

              getDriverLocationUpdatesAtRealTime(driverCurrentLatLng);




              }

            ),
            ),
            ),



        ]
      )
    );
  }
}
