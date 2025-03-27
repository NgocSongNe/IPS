import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiScanner {
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
