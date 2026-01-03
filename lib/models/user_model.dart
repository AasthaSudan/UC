import 'package:firebase_database/firebase_database.dart';

class UserModel {
  String? phone;
  String? name;
  String? id;
  String? email;
  String? address;

  UserModel({
    this.phone,
    this.name,
    this.email,
    this.id,
    this.address,
  });

  UserModel.fromSnapshot(DataSnapshot snap) {
    var data = snap.value as Map;

    phone = data["phone"];
    name = data["name"];
    email = data["email"];
    address = data["address"];
    id = snap.key;
  }
}
