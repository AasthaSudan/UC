import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class OpenRouteService {
  // Get your free API key from https://openrouteservice.org/dev/#/signup
  static const String apiKey = "YOUR_API_KEY_HERE";
  static const String baseUrl = "https://api.openrouteservice.org";

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  /// Get route from start to end using OSRM (primary) or OpenRouteService (fallback)
  Future<Map<String, dynamic>?> getRoute(LatLng start, LatLng end) async {
    // Validate coordinates
    if (!_isValidCoordinate(start) || !_isValidCoordinate(end)) {
      print('Invalid coordinates provided');
      return null;
    }

    // Try OSRM first (free and fast)
    try {
      return await _getRouteFromOSRM(start, end);
    } catch (e) {
      print('OSRM failed, trying OpenRouteService: $e');
      // Fallback to OpenRouteService
      return await _getRouteFromOpenRouteService(start, end);
    }
  }

  /// Get route from OSRM (Open Source Routing Machine)
  Future<Map<String, dynamic>?> _getRouteFromOSRM(LatLng start, LatLng end) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

      final response = await _dio.get(
        url,
        queryParameters: {
          'overview': 'full',
          'geometries': 'polyline',
          'steps': 'true',
        },
      );

      if (response.statusCode == 200) {
        var data = response.data;

        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          var route = data['routes'][0];

          print('OSRM route found:');
          print('  Distance: ${route['distance']} meters');
          print('  Duration: ${route['duration']} seconds');
          print('  Geometry: ${route['geometry']?.substring(0, 50)}...');

          return {
            'routes': [
              {
                'summary': {
                  'distance': route['distance'].toDouble(),
                  'duration': route['duration'].toDouble(),
                },
                'geometry': route['geometry'],
              }
            ]
          };
        } else {
          print('OSRM returned no valid routes');
        }
      } else {
        print('OSRM returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting route from OSRM: $e');
      rethrow; // Re-throw to trigger fallback
    }
    return null;
  }

  /// Get route from OpenRouteService (fallback)
  Future<Map<String, dynamic>?> _getRouteFromOpenRouteService(LatLng start, LatLng end) async {
    if (apiKey == "YOUR_API_KEY_HERE") {
      print('OpenRouteService API key not configured');
      return null;
    }

    try {
      final response = await _dio.post(
        '$baseUrl/v2/directions/driving-car',
        options: Options(
          headers: {
            'Authorization': apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'coordinates': [
            [start.longitude, start.latitude],
            [end.longitude, end.latitude],
          ],
        },
      );

      if (response.statusCode == 200) {
        print('OpenRouteService route found');
        return response.data;
      } else {
        print('OpenRouteService returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting route from OpenRouteService: $e');
      if (e is DioException) {
        print('DioException details: ${e.message}');
        print('Response: ${e.response?.data}');
      }
    }
    return null;
  }

  /// Search for places using Nominatim (OpenStreetMap's geocoding service)
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty || query.length < 2) {
      return [];
    }

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '10',
          'countrycodes': 'in', // Restrict to India
          'bounded': '1', // Prefer results within viewbox
        },
        options: Options(
          headers: {
            'User-Agent': 'FlutterTripApp/1.0',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(response.data);
        print('Found ${results.length} places for query: $query');
        return results;
      }
    } catch (e) {
      print('Error searching places: $e');
      if (e is DioException) {
        print('DioException: ${e.message}');
      }
    }
    return [];
  }

  /// Reverse geocode: convert coordinates to address
  Future<Map<String, dynamic>?> reverseGeocode(LatLng location) async {
    if (!_isValidCoordinate(location)) {
      print('Invalid coordinate for reverse geocoding');
      return null;
    }

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': location.latitude,
          'lon': location.longitude,
          'format': 'json',
          'addressdetails': '1',
        },
        options: Options(
          headers: {
            'User-Agent': 'FlutterTripApp/1.0',
          },
        ),
      );

      if (response.statusCode == 200) {
        print('Reverse geocoded: ${response.data['display_name']}');
        return response.data;
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
    return null;
  }

  /// Decode polyline string to list of LatLng points
  /// Supports both precision 5 (OSRM/Google) and precision 6 (OpenRouteService)
  List<LatLng> decodePolyline(String encoded, {int precision = 5}) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    // Precision factor: 1E5 for precision 5, 1E6 for precision 6
    double precisionFactor = precision == 6 ? 1E6 : 1E5;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      // Decode latitude
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      // Decode longitude
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latitude = lat / precisionFactor;
      double longitude = lng / precisionFactor;

      points.add(LatLng(latitude, longitude));
    }

    print("Decoded ${points.length} points from polyline");
    return points;
  }

  /// Validate if coordinate is within valid range
  bool _isValidCoordinate(LatLng coord) {
    return coord.latitude >= -90 &&
        coord.latitude <= 90 &&
        coord.longitude >= -180 &&
        coord.longitude <= 180;
  }

  /// Get formatted address from Nominatim result
  String getFormattedAddress(Map<String, dynamic> result) {
    if (result.containsKey('display_name')) {
      return result['display_name'];
    }

    if (result.containsKey('address')) {
      var address = result['address'];
      List<String> parts = [];

      if (address.containsKey('road')) parts.add(address['road']);
      if (address.containsKey('suburb')) parts.add(address['suburb']);
      if (address.containsKey('city')) parts.add(address['city']);
      if (address.containsKey('state')) parts.add(address['state']);
      if (address.containsKey('postcode')) parts.add(address['postcode']);

      return parts.join(', ');
    }

    return 'Unknown location';
  }

  /// Calculate distance between two points (Haversine formula)
  double calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, start, end);
  }

  /// Cleanup method
  void dispose() {
    _dio.close();
  }
}

// Extension method to add decodePolyline directly to OpenRouteService
extension PolylineDecoder on OpenRouteService {
  // Already included in the main class above
}