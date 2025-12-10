import 'package:firebase_database/firebase_database.dart';
import 'global.dart';
import 'user_model.dart';

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

  static Future<String> searchAddressForGeographicCoOrdinates(Position position, context) async {
    String apiUrl = ''; // You need to define the API URL
    String humanReadableAddress = "";
    var requestResponse = await RequestAssistant.receiveRequest(apiUrl);

    if (requestResponse != "Error Occurred. Failed. No Response.") {
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];

      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLatitude = position.latitude;
      userPickUpAddress.locationLongitude = position.longitude;
      userPickUpAddress.locationName = humanReadableAddress;

      Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);
    }
    return humanReadableAddress;
  }
}
