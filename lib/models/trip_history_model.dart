// class TripHistoryModel {
//   String? time;
//   String? originAddress;
//   String? destinationAddress;
//   String? status;
//   String? fareAmount;
//   String? driverName;
//   String? car_details;
//   String? ratings;
//
//   TripHistoryModel({
//     this.time,
//     this.originAddress,
//     this.destinationAddress,
//     this.status,
//     this.fareAmount,
//     this.driverName,
//     this.car_details,
//     this.ratings,
// });
//
//   TripHistoryModel.fromSnapshot(DataSnapshot snapshot) {
//     time=(snapshot.value as Map)["time"];
//     originAddress=(snapshot.value as Map)["originAddress"];
//     destinationAddress=(snapshot.value as Map)["destinationAddress"];
//     status=(snapshot.value as Map)["status"];
//     fareAmount=(snapshot.value as Map)["fareAmount"];
//     driverName=(snapshot.value as Map)["driverName"];
//     car_details=(snapshot.value as Map)["car_details"];
//     ratings=(snapshot.value as Map)["ratings"];
//   }
// }