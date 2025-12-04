class AssistantMethods {

  static void readCurrentOnlineUserInfo() async {
    currentUser=firebaseAuth.currentUser;
    DatabaseReference userRef=FirebaseDatabase.instance
    .ref()
    .child("users")
    .child(currentUser!.uid);

    userRed.once().then((snap) {
      if(snap.snapshot.value!=null) {
        userModelCurrentInfo=UserModel.fromSnapshot(snap.snapshot);
      }
    })
  }
}