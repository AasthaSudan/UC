import '../models/active_nearby_available_drivers.dart';

class GeoFireAssistant {
  static List<ActiveNearbyAvailableDrivers>
  activeNearbyAvailableDriversList = [];

  static void removeOfflineDriver(String driverId) {
    activeNearbyAvailableDriversList
        .removeWhere((driver) => driver.driverId == driverId);
  }

  static void updateDriverLocation(
      ActiveNearbyAvailableDrivers driverWhoMoved) {
    int index = activeNearbyAvailableDriversList.indexWhere(
          (driver) => driver.driverId == driverWhoMoved.driverId,
    );

    if (index != -1) {
      activeNearbyAvailableDriversList[index].locationLatitude =
          driverWhoMoved.locationLatitude;

      activeNearbyAvailableDriversList[index].locationLongitude =
          driverWhoMoved.locationLongitude;
    }
  }
}
