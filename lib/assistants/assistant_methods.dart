import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../global/global.dart';
import '../models/user_model.dart';
import '../models/directions.dart';
import '../info/app_info.dart';
import '../info/directions_details_info.dart';
import '../widgets/openroute_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AssistantMethods {
  static final OpenRouteService _routeService = OpenRouteService();

  static Future<void> readCurrentOnlineUserInfo() async {
    currentUser = firebaseAuth.currentUser;

    if (currentUser == null) return;

    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(currentUser!.uid);

    userRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
      }
    });
  }

  static Future<String> searchAddressForGeographicCoordinates(Position position, context) async {
    String humanReadableAddress = "";

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        humanReadableAddress = "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

        Directions userPickUpAddress = Directions();
        userPickUpAddress.locationLatitude = position.latitude;
        userPickUpAddress.locationLongitude = position.longitude;
        userPickUpAddress.locationName = humanReadableAddress;

        Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return humanReadableAddress;
  }

  static Future<DirectionsDetailsInfo?> obtainOriginToDestinationDirectionDetails(
      LatLng originPosition,
      LatLng destinationPosition
      ) async {
    try {
      print("Fetching route from OpenRouteService...");
      print("Origin: ${originPosition.latitude}, ${originPosition.longitude}");
      print("Destination: ${destinationPosition.latitude}, ${destinationPosition.longitude}");

      var routeData = await _routeService.getRoute(originPosition, destinationPosition);

      if (routeData == null) {
        print("No route data received from OpenRouteService");
        return null;
      }

      print("Route data received successfully");

      DirectionsDetailsInfo directionsDetailsInfo = DirectionsDetailsInfo();

      var route = routeData['routes'][0];
      var summary = route['summary'];

      double distanceInMeters = summary['distance'].toDouble();
      double distanceInKm = distanceInMeters / 1000;
      directionsDetailsInfo.distance_value = distanceInMeters.toInt();
      directionsDetailsInfo.distance_text = "${distanceInKm.toStringAsFixed(2)} km";

      print("Distance: ${directionsDetailsInfo.distance_text}");

      double durationInSeconds = summary['duration'].toDouble();
      double durationInMinutes = durationInSeconds / 60;
      directionsDetailsInfo.duration_value = durationInSeconds.toInt();
      directionsDetailsInfo.duration_text = "${durationInMinutes.toStringAsFixed(0)} mins";

      print("Duration: ${directionsDetailsInfo.duration_text}");

      directionsDetailsInfo.e_points = route['geometry'];
      print("Polyline encoded string length: ${directionsDetailsInfo.e_points?.length}");

      return directionsDetailsInfo;
    } catch (e) {
      print("Error getting directions: $e");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    return await _routeService.searchPlaces(query);
  }

  static double calculateFareAmountFromOriginToDestination(DirectionsDetailsInfo directionDetailsInfo) {
    double timeTraveledFareAmount = ((directionDetailsInfo.duration_value ?? 0) / 60) * 0.1;
    double distanceTraveledFareAmount = ((directionDetailsInfo.distance_value ?? 0) / 1000) * 0.1;

    double totalFareAmount = timeTraveledFareAmount + distanceTraveledFareAmount;
    double localCurrencyAmount = totalFareAmount * 107;

    if(driverVehicleType == "Bike") {
      double resultFareAmount = ((localCurrencyAmount.truncate()) * 0.8);
      resultFareAmount;
    }

    else if(driverVehicleType == "CNG") {
      double resultFareAmount = ((localCurrencyAmount.truncate()) * 1.5);
      resultFareAmount;
    }

    else {
      double resultFareAmount = ((localCurrencyAmount.truncate()) * 2);
      resultFareAmount;
    }

    return localCurrencyAmount.truncate().toDouble();
  }

  static sendNotificationToDriverNow(String token, String rideRequestId, context) async {
    String destinationAddress = Provider.of<AppInfo>(context, listen: false).userDropOffLocation!.locationName!;

    Map<String, String> headerNotification = {
      'Content-Type': 'application/json',
      'Authorization': 'key=YOUR_FCM_SERVER_KEY_HERE'
    };

    Map bodyNotification = {
      'body': 'Destination Address: $destinationAddress.',
      'title': 'New Ride Request'
    };

    Map dataMap = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': '1',
      'status': 'done',
      'ride_request_id': rideRequestId
    };

    Map official = {
      'notification': bodyNotification,
      'priority': 'high',
      'data': dataMap,
      'to': token,
    };

    var response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: headerNotification,
      body: jsonEncode(official),
    );
    return response;
  }

  static pauseLiveLocationUpdates() {
    streamSubscriptionPosition!.pause();
    // Geofire.removeLocation(firebaseAuth.currentUser!.uid);
  }
}