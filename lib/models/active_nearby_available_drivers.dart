class ActiveNearbyAvailableDrivers {
  String driverId;
  String name;
  String phone;
  double locationLatitude;
  double locationLongitude;
  String carModel;
  String carType;

  ActiveNearbyAvailableDrivers({
    required this.driverId,
    required this.name,
    required this.phone,
    required this.locationLatitude,
    required this.locationLongitude,
    required this.carModel,
    required this.carType,
  });

  factory ActiveNearbyAvailableDrivers.fromMap(Map<dynamic, dynamic> map, String id) {
    return ActiveNearbyAvailableDrivers(
      driverId: id,
      name: map['name'] ?? "",
      phone: map['phone'] ?? "",
      locationLatitude: map['latitude'] ?? 0.0,
      locationLongitude: map['longitude'] ?? 0.0,
      carModel: map['car_details']['car_model'] ?? "",
      carType: map['car_details']['car_type'] ?? "",
    );
  }
}
