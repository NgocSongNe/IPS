// mapcontroller.dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

class CustomMapController {
  final MapController _mapController;
  late WiFiPredictor _wifiPredictor;

  CustomMapController(this._mapController) {
    _wifiPredictor = WiFiPredictor();
  }

  // Phương thức di chuyển bản đồ đến vị trí người dùng
  void moveToLocation(LatLng location, double zoom) {
    _mapController.move(location, zoom);
  }

  // Quét WiFi và dự đoán vị trí
  Future<void> scanAndPredictLocation() async {
    if (await WiFiScanner.checkPermissions()) {
      List<WiFiAccessPoint> wifiList = await WiFiScanner.scanWiFi();
      if (wifiList.isNotEmpty) {
        List<double> rssiInput = wifiList.map((ap) => ap.level.toDouble()).toList();
        List<double> position = await _wifiPredictor.predict(rssiInput);
        // Di chuyển bản đồ đến vị trí người dùng
        moveToLocation(LatLng(position[0], position[1]), 18); // Cập nhật với zoom level 18
      } else {
        print("⚠️ Không tìm thấy mạng WiFi nào.");
      }
    }
  }
}

class WiFiScanner {
  // Kiểm tra & yêu cầu quyền truy cập WiFi
  static Future<bool> checkPermissions() async {
    if (await Permission.locationWhenInUse.request().isGranted &&
        await Permission.locationAlways.request().isGranted &&
        await Permission.nearbyWifiDevices.request().isGranted) {
      return true;
    }
    print("❌ Quyền truy cập WiFi bị từ chối!");
    return false;
  }

  // Quét danh sách WiFi hiện có
  static Future<List<WiFiAccessPoint>> scanWiFi() async {
    bool hasPermission = await checkPermissions();
    if (!hasPermission) return [];

    try {
      // Kiểm tra xem có thể quét WiFi không
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan != CanStartScan.yes) {
        print("❌ Thiết bị không hỗ trợ quét WiFi hoặc thiếu quyền!");
        return [];
      }

      // Bắt đầu quét WiFi
      await WiFiScan.instance.startScan();

      // Chờ 2 giây để có dữ liệu
      await Future.delayed(Duration(seconds: 2));

      // Lấy danh sách WiFi
      List<WiFiAccessPoint> wifiList = await WiFiScan.instance.getScannedResults();

      if (wifiList.isEmpty) {
        print("⚠️ Không tìm thấy mạng WiFi nào.");
      }
      return wifiList;
    } catch (e) {
      print("⚠️ Lỗi khi quét WiFi: $e");
      return [];
    }
  }
}

class WiFiPredictor {
  late Interpreter _interpreter;

  // Load the model
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/model.tflite');
    print("Model loaded successfully");
  }

  // Predict location from RSSI values
  Future<List<double>> predict(List<double> input) async {
    if (_interpreter == null) {
      throw Exception("Model is not loaded");
    }

    // Reshape input data if needed
    var inputData = [input]; // Reshaped as a 2D array: [[rssi1, rssi2, ...]]
    
    // Output data with a shape of [1, 2] (latitude, longitude)
    var outputData = List.filled(2, 0.0); // [lat, lng]
    
    // Run the model prediction
    _interpreter.run(inputData, outputData);
    
    print("Prediction result: $outputData");
    return outputData;
  }
}
