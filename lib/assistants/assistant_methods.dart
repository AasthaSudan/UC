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
import '../models/trip_history_model.dart';

class AssistantMethods {
  static final OpenRouteService _routeService = OpenRouteService();

  static Future<void> readCurrentOnlineUserInfo() async {
    currentUser = firebaseAuth.currentUser;

    if (currentUser == null) {
      print("Error: User information is null - No user logged in");
      return;
    }

    try {
      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(currentUser!.uid);

      DatabaseEvent event = await userRef.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists && snapshot.value != null) {
        userModelCurrentInfo = UserModel.fromSnapshot(snapshot);
        print("User info loaded: ${userModelCurrentInfo?.name}");
      } else {
        print("Error: User information is null - No data in database");
      }
    } catch (e) {
      print("Error reading user info: $e");
    }
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

  static double calculateFareAmountFromOriginToDestination(
      DirectionsDetailsInfo directionDetailsInfo) {

    double timeTraveledFareAmount =
        ((directionDetailsInfo.duration_value ?? 0) / 60) * 0.1;

    double distanceTraveledFareAmount =
        ((directionDetailsInfo.distance_value ?? 0) / 1000) * 0.1;

    double totalFareAmount =
        timeTraveledFareAmount + distanceTraveledFareAmount;

    double localCurrencyAmount = totalFareAmount * 107;

    String vehicleType = onlineDriverData.car_type ?? "Car";

    double finalFareAmount;

    if (vehicleType == "Bike") {
      finalFareAmount = localCurrencyAmount * 0.8;
    }
    else if (vehicleType == "CNG") {
      finalFareAmount = localCurrencyAmount * 1.5;
    }
    else {
      finalFareAmount = localCurrencyAmount * 2;
    }

    return finalFareAmount.truncate().toDouble();
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
      'rideRequestId': rideRequestId
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
    streamSubscriptionPosition?.pause();
  }

  static void readTripKeysForOnlineDriver(context) {
    FirebaseDatabase.instance.ref().child("All Ride Requests").orderByChild("driverId").equalTo(firebaseAuth.currentUser!.uid).once().then((event) {
      if(event.snapshot.value != null) {
        Map keysTripsId = event.snapshot.value as Map;
        int overAllTripsCounter = keysTripsId.length;
        Provider.of<AppInfo>(context, listen: false).updateOverAllTripsCounter(overAllTripsCounter);

        List<String> tripKeys = [];
        keysTripsId.forEach((key, value) {
          tripKeys.add(key);
        });
        Provider.of<AppInfo>(context, listen: false).updateOverAllTripsKeys(tripKeys);

        readTripHistoryInfo(context);
      }
    });
  }

  static void readTripHistoryInfo(context) {
    var tripAllKeys = Provider.of<AppInfo>(context, listen: false).historyTripKeysList;
    for(String eachKey in tripAllKeys) {
      FirebaseDatabase.instance.ref()
          .child("All Ride Requests")
          .child(eachKey)
          .once()
          .then((event) {
        var eachTripHistory = TripHistoryModel.fromSnapshot(event.snapshot);

        if ((event.snapshot.value as Map)["status"] == "ended") {
          Provider.of<AppInfo>(context, listen: false).updateTripHistoryInfo(eachTripHistory);
        }
      });
    }
  }

  static void readDriverEarnings(context) {
    FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(firebaseAuth.currentUser!.uid)
        .child("earnings")
        .once()
        .then((event) {
      if (event.snapshot.value != null) {
        String driverEarnings = event.snapshot.value.toString();
        Provider.of<AppInfo>(context, listen: false).updateDriverTotalEarnings(driverEarnings);
      }
    });

    readTripKeysForOnlineDriver(context);
  }

  static void readDriverRatings(context) {
    FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(firebaseAuth.currentUser!.uid)
        .child("ratings")
        .once()
        .then((event) {
      if (event.snapshot.value != null) {
        String driverRatings = event.snapshot.value.toString();
        Provider.of<AppInfo>(context, listen: false).updateDriverAverageRatings(driverRatings);
      }
    });
  }
}