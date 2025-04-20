// lib/services/compass_service.dart
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

class CompassService {
  double _compassHeading = 0.0;

  // Hàm khởi tạo cảm biến la bàn
  void initCompass(Function(double) onHeadingChanged) {
    magnetometerEvents.listen((MagnetometerEvent event) {
      double heading = atan2(event.y, event.x) * (180 / pi);
      if (heading < 0) {
        heading += 360;
      }
      _compassHeading = heading;
      onHeadingChanged(_compassHeading);  // Gửi lại hướng la bàn
    });
  }

  // Trả về giá trị góc la bàn hiện tại
  double getCompassHeading() {
    return _compassHeading;
  }
}
