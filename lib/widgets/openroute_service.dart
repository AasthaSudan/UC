import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class OpenRouteService {

  static const String apiKey = "YOUR_API_KEY_HERE";
  static const String baseUrl = "https://api.openrouteservice.org";

  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> getRoute(LatLng start, LatLng end) async {
    try {
      final response = await _dio.get(
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}',
        queryParameters: {
          'overview': 'full',
          'geometries': 'polyline',
        },
      );

      if (response.statusCode == 200) {
        var data = response.data;
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          var route = data['routes'][0];
          return {
            'routes': [
              {
                'summary': {
                  'distance': route['distance'],
                  'duration': route['duration'],
                },
                'geometry': route['geometry'],
              }
            ]
          };
        }
      }
    } catch (e) {
      print('Error getting route from OSRM: $e');
      return await _getRouteFromOpenRouteService(start, end);
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getRouteFromOpenRouteService(LatLng start, LatLng end) async {
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
        return response.data;
      }
    } catch (e) {
      print('Error getting route from OpenRouteService: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '10',
          'countrycodes': 'in',
        },
        options: Options(
          headers: {
            'User-Agent': 'FlutterTripApp/1.0',
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Error searching places: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> reverseGeocode(LatLng location) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': location.latitude,
          'lon': location.longitude,
          'format': 'json',
        },
        options: Options(
          headers: {
            'User-Agent': 'FlutterTripApp/1.0',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
    return null;
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latitude = lat / 1E5;
      double longitude = lng / 1E5;

      points.add(LatLng(latitude, longitude));
    }

    print("Decoded ${points.length} points from polyline");
    return points;
  }
}