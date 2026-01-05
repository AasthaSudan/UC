class GeoFireAssistant{
  static List<ActiveNearbyAvailableDrivers> nearbyAvailableDriversList = [];

  static void deleteOfflibeDrivers(String driverId) {
    int index = nearbyAvailableDriversList.indexWhere((driver) => driver.driverId == driverId);
    if (index != -1) {
      nearbyAvailableDriversList.removeAt(index);
    }
  }

  static void updateOfflibeDrivers(ActiveNearbyAvailableDrivers driver) {
    int index = nearbyAvailableDriversList.indexWhere((nearbyDriver) => nearbyDriver.driverId == driver.driverId);
    if (index != -1) {
      nearbyAvailableDriversList[index] = driver;
    }
    activeNearbyAvailableDrivers.driverId = driverWhoMove.driverId;
    activeNearbyAvailableDrivers.locationLatitude = driverWhoMove.locationLatitude;
    activeNearbyAvailableDrivers.locationLongitude = driverWhoMove.locationLongitude;


}