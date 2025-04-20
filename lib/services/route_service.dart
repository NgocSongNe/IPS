import 'package:latlong2/latlong.dart';
import 'dart:math';

class RouteService {
  // Hàm tính toán khoảng cách giữa hai điểm
  double calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371; // in kilometers
    double dLat = (point2.latitude - point1.latitude) * (pi / 180);
    double dLon = (point2.longitude - point1.longitude) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(point1.latitude * (pi / 180)) *
            cos(point2.latitude * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c * 1000; // return distance in meters
  }

  // Hàm tính toán hướng đi giữa ba điểm
  String getDirection(LatLng p1, LatLng p2, LatLng p3) {
    double v1x = p2.longitude - p1.longitude;
    double v1y = p2.latitude - p1.latitude;
    double v2x = p3.longitude - p2.longitude;
    double v2y = p3.latitude - p2.latitude;

    double crossProduct = v1x * v2y - v1y * v2x;
    double dotProduct = v1x * v2x + v1y * v2y;
    double mag1 = sqrt(v1x * v1x + v1y * v1y);
    double mag2 = sqrt(v2x * v2x + v2y * v2y);
    double angle = acos(dotProduct / (mag1 * mag2)) * 180 / pi;

    if (angle < 10) {
      return "Đi thẳng";
    } else if (crossProduct > 0) {
      return "Rẽ trái";
    } else {
      return "Rẽ phải";
    }
  }

  // Hàm tính toán khoảng cách tổng của đường đi
  double calculatePathDistance(List<LatLng> route) {
    if (route.length < 2) return 0.0;
    double totalDistance = 0.0;
    for (var i = 0; i < route.length - 1; i++) {
      totalDistance += calculateDistance(route[i], route[i + 1]);
    }
    return totalDistance;
  }

  // Hàm làm mịn đường đi (smoothing route)
  List<LatLng> smoothRoute(List<LatLng> route, {int segmentsPerPoint = 10}) {
    if (route.length < 2) return route;

    List<LatLng> smoothedRoute = [];

    LatLng p0 = route.first;
    LatLng p1 = route.first;
    LatLng p2 = route[1];
    LatLng p3 = route.length > 2 ? route[2] : route[1];

    smoothedRoute.add(route.first);

    for (int i = 0; i < route.length - 1; i++) {
      p0 = i > 0 ? route[i - 1] : route.first;
      p1 = route[i];
      p2 = route[i + 1];
      p3 = i + 2 < route.length ? route[i + 2] : route[i + 1];

      for (int j = 1; j <= segmentsPerPoint; j++) {
        double t = j / segmentsPerPoint;
        double t2 = t * t;
        double t3 = t2 * t;

        double x = 0.5 *
            ((2 * p1.latitude) +
              (-p0.latitude + p2.latitude) * t +
                (2 * p0.latitude -
                        5 * p1.latitude +
                        4 * p2.latitude - 
                        p3.latitude) * t2 +
                (-p0.latitude + 3 * p1.latitude - 3 * p2.latitude + p3.latitude) * t3);

        double y = 0.5 *
            ((2 * p1.longitude) +
              (-p0.longitude + p2.longitude) * t +
                (2 * p0.longitude - 5 * p1.longitude + 4 * p2.longitude - p3.longitude) * t2 +
                (-p0.longitude + 3 * p1.longitude - 3 * p2.longitude + p3.longitude) * t3);

        smoothedRoute.add(LatLng(x, y));
      }
    }

    smoothedRoute.add(route.last);
    return smoothedRoute;
  }

  bool _isPathBlocked(LatLng start, LatLng end,  List<List<LatLng>> walls) {
    for (var wall in walls) {
      for (int i = 0; i < wall.length - 1; i++) {
        if (_doLinesIntersect(start, end, wall[i], wall[i + 1])) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int j = polygon.length - 1;
    bool inside = false;

    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].latitude > point.latitude) !=
              (polygon[j].latitude > point.latitude)) &&
          (point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                      (point.latitude - polygon[i].latitude) /
                      (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  bool _doLinesIntersect(LatLng p1, LatLng q1, LatLng p2, LatLng q2) {
    int orientation(LatLng a, LatLng b, LatLng c) {
      double value = (b.latitude - a.latitude) * (c.longitude - b.longitude) -
          (b.longitude - a.longitude) * (c.latitude - b.latitude);
      if (value == 0) return 0;
      return (value > 0) ? 1 : 2;
    }

    bool onSegment(LatLng a, LatLng b, LatLng c) {
      return b.latitude <= max(a.latitude, c.latitude) &&
          b.latitude >= min(a.latitude, c.latitude) &&
          b.longitude <= max(a.longitude, c.longitude) &&
          b.longitude >= min(a.longitude, c.longitude);
    }

    int o1 = orientation(p1, q1, p2);
    int o2 = orientation(p1, q1, q2);
    int o3 = orientation(p2, q2, p1);
    int o4 = orientation(p2, q2, q1);

    if (o1 != o2 && o3 != o4) return true;

    if (o1 == 0 && onSegment(p1, p2, q1)) return true;
    if (o2 == 0 && onSegment(p1, q2, q1)) return true;
    if (o3 == 0 && onSegment(p2, p1, q2)) return true;
    if (o4 == 0 && onSegment(p2, q1, q2)) return true;

    return false;
  }
  
  double heuristic(String current, String goal, List<Map<String, dynamic>> poiList) {
    final currentPoi = poiList.firstWhere((poi) => poi['rp'] == current);
    final goalPoi = poiList.firstWhere((poi) => poi['rp'] == goal);
    final currentCoords = currentPoi['coordinates'] as LatLng;
    final goalCoords = goalPoi['coordinates'] as LatLng;
    return calculateDistance(currentCoords, goalCoords);
  }

}
