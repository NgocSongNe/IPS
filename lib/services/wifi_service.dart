// wifi_service.dart
import 'package:flutter_application_1/ultils/wifi_scanner.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
class WifiService {
  Future<void> startWifiTracking(Function updatePosition) async {
    Timer.periodic(Duration(seconds: 10), (timer) async {
      List<WiFiAccessPoint> wifiNetworks = await WifiScanner.scanWiFi();
      await sendWiFiDataToServer(wifiNetworks, updatePosition);  // Truyền callback để cập nhật vị trí người dùng
    });
  }

  Future<void> stopWifiTracking(Timer? wifiScanTimer) async {
    wifiScanTimer?.cancel();  // Dừng Timer
    print("❌ Dừng quét Wi-Fi");
  }

  Future<void> sendWiFiDataToServer(List<WiFiAccessPoint> wifiNetworks, Function updatePosition) async {
    final url = Uri.parse('http://192.168.1.11:8765/predict'); // URL server Node.js

    try {
      if (wifiNetworks.isEmpty) {
        print("❌ Không tìm thấy mạng Wi-Fi");
        return;
      }

      List<String> macAddresses = [
        // Các địa chỉ MAC của các mạng cần theo dõi
        "88:dc:97:12:62:cf", "8e:dc:97:12:65:63", "8e:dc:97:12:65:21", "8e:dc:97:12:65:64",
        "8e:dc:97:12:65:2b", "88:dc:97:12:64:c4", "88:dc:97:12:62:c6", "8e:dc:97:12:62:cf"
        // Thêm các địa chỉ MAC khác nếu cần
      ];

      // Duyệt qua các mạng Wi-Fi quét được và lưu RSSI vào map
      Map<String, int> macToRssi = {};
      for (var wifi in wifiNetworks) {
        if (macAddresses.contains(wifi.bssid)) {
          macToRssi[wifi.bssid] = wifi.level;
        }
      }

      List<int> wifiData = [];
      for (var mac in macAddresses) {
        wifiData.add(macToRssi[mac] ?? -100); // Nếu không có mạng, gán -100
      }

      // Gửi dữ liệu RSSI lên server
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rssi': wifiData}),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        List coordinates = responseData['coordinates'];
        int rp = responseData['rp'];

        // Cập nhật vị trí người dùng
        updatePosition(coordinates, rp);
      } else {
        print("❌ Gửi dữ liệu thất bại: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Lỗi khi quét và gửi dữ liệu Wi-Fi: $e");
    }
  }
}
