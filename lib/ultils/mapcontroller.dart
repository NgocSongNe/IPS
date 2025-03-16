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

  void moveToLocation(LatLng location, double zoom) {
    _mapController.move(location, zoom);
  }

  Future<void> loadModel() async {
    await _wifiPredictor.loadModel();
  }

  Future<void> scanAndPredictLocation() async {
    if (await WiFiScanner.checkPermissions()) {
      List<WiFiAccessPoint> wifiList = await WiFiScanner.scanWiFi();
      if (wifiList.isNotEmpty) {
        // Chọn 3 tín hiệu mạnh nhất hoặc thêm giá trị mặc định nếu thiếu
        List<double> rssiInput = wifiList.map((ap) => ap.level.toDouble()).toList();
        if (rssiInput.length > 3) {
          rssiInput.sort((a, b) => b.compareTo(a));
          rssiInput = rssiInput.sublist(0, 3);
        } else if (rssiInput.length < 3) {
          while (rssiInput.length < 3) {
            rssiInput.add(-100.0);
          }
        }
        List<double> position = await _wifiPredictor.predict(rssiInput);
        moveToLocation(LatLng(position[0], position[1]), 18);
      } else {
        print("⚠️ Không tìm thấy mạng WiFi nào.");
      }
    }
  }
}

class WiFiScanner {
  static Future<bool> checkPermissions() async {
    var statusWhenInUse = await Permission.locationWhenInUse.request();
    var statusAlways = await Permission.locationAlways.request();
    var statusNearby = await Permission.nearbyWifiDevices.request();

    if (statusWhenInUse.isGranted && statusAlways.isGranted && statusNearby.isGranted) {
      return true;
    }

    if (await Permission.locationWhenInUse.isPermanentlyDenied ||
        await Permission.locationAlways.isPermanentlyDenied ||
        await Permission.nearbyWifiDevices.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }

    print("❌ Quyên truy cập WiFi bị từ chối!");
    return false;
  }

  static Future<List<WiFiAccessPoint>> scanWiFi() async {
    bool hasPermission = await checkPermissions();
    if (!hasPermission) return [];

    try {
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan != CanStartScan.yes) {
        print("❌ Thiết bị không hỗ trợ quét WiFi hoặc thiếu quyên!");
        return [];
      }

      await WiFiScan.instance.startScan();
      await Future.delayed(Duration(seconds: 2));
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

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/model.tflite');
    print("Model loaded successfully");
  }

  Future<List<double>> predict(List<double> input) async {
    if (_interpreter == null) {
      throw Exception("Model is not loaded");
    }

    var inputData = [input];
    var outputData = List.filled(2, 0.0);
    _interpreter.run(inputData, outputData);
    print("Prediction result: $outputData");
    return outputData;
  }
}