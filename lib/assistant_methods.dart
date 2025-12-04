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

    DatabaseEvent event = await userRef.once();

    if (event.snapshot.value != null) {
      userModelCurrentInfo = UserModel.fromSnapshot(event.snapshot);
    }
  }
}
