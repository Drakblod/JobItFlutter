import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/route_point.dart';

class MapsService {
  final String _apiKey = Constants.googleMapsApiKey;

  Future<List<RoutePoint>> getRoadPath(double startLat, double startLng, double endLat, double endLng) async {
    try {
      final origin = '$startLat,$startLng';
      final destination = '$endLat,$endLng';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final encodedPoints = data['routes'][0]['overview_polyline']['points'] as String;
          final decoded = _decodePolyline(encodedPoints);
          
          List<RoutePoint> route = [];
          for (int i = 0; i < decoded.length; i++) {
            route.add(RoutePoint(
              order: i,
              latitude: decoded[i][0],
              longitude: decoded[i][1],
            ));
          }
          return route;
        }
      }
    } catch (e) {
      debugPrint('Directions API Error: $e');
    }

    // Fallback: Return straight line
    return [
      RoutePoint(order: 0, latitude: startLat, longitude: startLng),
      RoutePoint(order: 1, latitude: endLat, longitude: endLng),
    ];
  }

  // Standard Polyline Decoding Algorithm
  List<List<double>> _decodePolyline(String encoded) {
    List<List<double>> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
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

      poly.add([lat / 1E5, lng / 1E5]);
    }
    return poly;
  }

  Future<List<double>?> searchAddress(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedQuery&key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return [(location['lat'] as num).toDouble(), (location['lng'] as num).toDouble()];
        }
      }
    } catch (e) {
      debugPrint('Geocode API Error: $e');
    }
    return null;
  }
}
