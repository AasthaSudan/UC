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
        userModelCurrentInfo = UserModel.fromSnapshot(event.snapshot);
      }
    });
  }
  static Future<String> searchAddressForGeographicCoOrdinates(Position position, context) async {
    Strin apiUrl= ;
    String humanReadableAddress="";
    var requestResponse=await RequestAssistant.receiveRequest(apiUrl);

    if(requetResponse != "Error Occurred. Failed. No Response.") {
      humanReadableAddress=requestResponse["results"][0]["formatted_address"];

      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLatitude=position.latitude;
      userPickUpAddress.locationLongitude=position.longitude;

    }
    return humanReadableAddress;
  }
}
