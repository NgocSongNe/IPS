// lib/services/route_service.dart
import 'package:flutter_application_1/models/category_model.dart';
import 'package:flutter_application_1/models/map_model.dart';
import 'package:latlong2/latlong.dart'; 
import 'dart:math';
class RouteService {
  List<String> directions = [];
  List<double> segmentDistances = [];

  void calculateDirections(List<LatLng> route) {
    directions.clear();
    segmentDistances.clear();
    for (int i = 0; i < route.length - 1; i++) {
      double distance = _calculateDistance(route[i], route[i + 1]);
      segmentDistances.add(distance);

      directions.add("Đi thẳng đến đích");
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Tính toán khoảng cách giữa hai điểm LatLng
    const earthRadius = 6371; // in km
    double dLat = (point2.latitude - point1.latitude) * (pi / 180);
    double dLon = (point2.longitude - point1.longitude) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(point1.latitude * (pi / 180)) *
            cos(point2.latitude * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c * 1000; // in meters
  }
}
