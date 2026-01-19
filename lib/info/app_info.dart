import 'package:flutter/cupertino.dart';
import '../models/directions.dart';

class AppInfo extends ChangeNotifier {
  Directions? userPickUpLocation, userDropOffLocation;
  int countTotalTrips = 0;
  String driverTotalEarnings=0;
  String driverAverageRatings=0;
  List<StritoryTripKeysList=[];
  List<TripsHistoryModel> allTripsHistoryInformationList=[];

  void updatePickUpLocationAddress(Directions userPickUpAddress) {
    userPickUpLocation = userPickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Directions dropOffAddress) {
    userDropOffLocation = dropOffAddress;
    notifyListeners();
  }

  updateOverAllTripsCounter(int overAllTrpsCounter){
    countTotalTrips=overAllTrpsCounter;
    notifyListeners();
  }

  updateOverAllTripsKeys(List<String> tripKeys){
    keysTripsId=tripKeys;
    notifyListeners();
  )

    updateTripHistoryInfo(TripHistoryModel tripHistoryModel){
      allTripHistoryInfo.add(tripHistoryModel);
      notifyListeners();
    }

    updateDriverTotalEarnings(String driverTotalEarnings){
      driverTotalEarnings=driverEarnings;
    }

    updateDriverAverageRatings(String driverAverageTrips){
      driverAverageTrips=driverRatings;
    }
}
