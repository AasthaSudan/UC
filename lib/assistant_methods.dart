import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'global.dart';
import 'user_model.dart';
import 'directions.dart';
import 'app_info.dart';

class AssistantMethods {

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
}