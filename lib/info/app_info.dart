import 'package:flutter/cupertino.dart';
import '../models/directions.dart';
import '../models/trip_history_model.dart';

class AppInfo extends ChangeNotifier {
  Directions? userPickUpLocation, userDropOffLocation;
  int countTotalTrips = 0;
  String driverTotalEarnings = "0";
  String driverAverageRatings = "0";
  List<String> historyTripKeysList = [];
  List<TripHistoryModel> allTripsHistoryInformationList = [];

  void updatePickUpLocationAddress(Directions userPickUpAddress) {
    userPickUpLocation = userPickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Directions dropOffAddress) {
    userDropOffLocation = dropOffAddress;
    notifyListeners();
  }

  updateOverAllTripsCounter(int overAllTripsCounter) {
    countTotalTrips = overAllTripsCounter;
    notifyListeners();
  }

  updateOverAllTripsKeys(List<String> tripKeys) {
    historyTripKeysList = tripKeys;
    notifyListeners();
  }

  updateTripHistoryInfo(TripHistoryModel tripHistoryModel) {
    allTripsHistoryInformationList.add(tripHistoryModel);
    notifyListeners();
  }

  updateDriverTotalEarnings(String driverEarnings) {
    driverTotalEarnings = driverEarnings;
    notifyListeners();
  }

  updateDriverAverageRatings(String driverRatings) {
    driverAverageRatings = driverRatings;
    notifyListeners();
  }
}