class UserModel {
  String? phone;
  String? name;
  String? id;
  String? email;
  String? address;

  UserModel({
    this.name,
    this.phone,
    this.email,
    this.id,
    this.address
  });

  UserModel.fromSnapshot(DataSnapshot snap) {
    phone=(snap.value as dynamic)["phone"];
    name=(snap.value as dynamic)["phone"];
    id=snap.key;
    email=(snap.value as dynamic)["phone"];
    address=(snap.value as dynamic)["phone"];
  }
}