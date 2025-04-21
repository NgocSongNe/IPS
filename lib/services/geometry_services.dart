import 'package:latlong2/latlong.dart';

class GeometryService {
  // Hàm tính toán các giao điểm giữa các đoạn đường
  void computeHallwayIntersections(List<List<LatLng>> hallways, List<LatLng> waypoints) {
    for (int i = 0; i < hallways.length; i++) {
      for (int j = i + 1; j < hallways.length; j++) {
        var hallway1 = hallways[i];
        var hallway2 = hallways[j];
        for (int k = 0; k < hallway1.length - 1; k++) {
          for (int l = 0; l < hallway2.length - 1; l++) {
            LatLng? intersection = _findIntersection(
              hallway1[k], hallway1[k + 1],
              hallway2[l], hallway2[l + 1],
            );
            if (intersection != null && !waypoints.contains(intersection)) {
              waypoints.add(intersection);
              print("Added intersection waypoint: $intersection");
            }
          }
        }
      }
    }
  }

  // Hàm tìm giao điểm của hai đoạn đường
  LatLng? _findIntersection(LatLng p1, LatLng q1, LatLng p2, LatLng q2) {
    double x1 = p1.latitude, y1 = p1.longitude;
    double x2 = q1.latitude, y2 = q1.longitude;
    double x3 = p2.latitude, y3 = p2.longitude;
    double x4 = q2.latitude, y4 = q2.longitude;

    double denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if (denom == 0) return null;

    double t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom;
    double u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom;

    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      double x = x1 + t * (x2 - x1);
      double y = y1 + t * (y2 - y1);
      return LatLng(x, y);
    }
    return null;
  }
}
