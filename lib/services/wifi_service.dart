// wifi_service.dart
import 'package:flutter_application_1/ultils/wifi_scanner.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

  
class WifiService {
  final String baseurl= dotenv.env['API_URL'] ?? '';
  Future<void> startWifiTracking(Function updatePosition) async {
    Timer.periodic(Duration(seconds: 10), (timer) async {
      List<WiFiAccessPoint> wifiNetworks = await WifiScanner.scanWiFi();
      await sendWiFiDataToServer(wifiNetworks, updatePosition);  // Truyền callback để cập nhật vị trí người dùng
    });

  }

  Future<void> stopWifiTracking(Timer? wifiScanTimer) async {
    wifiScanTimer?.cancel();  // Dừng Timer
    print("Dừng quét Wi-Fi");
  }

  Future<void> sendWiFiDataToServer(List<WiFiAccessPoint> wifiNetworks, Function updatePosition) async {
    final url = Uri.parse('$baseurl/predict'); // URL server Node.js

    try {
      if (wifiNetworks.isEmpty) {
        print("Không tìm thấy mạng Wi-Fi");
        return;
      }

      List<String> macAddresses = [
        "88:dc:97:12:62:cf", "8e:dc:97:12:65:63", "8e:dc:97:12:65:21", "8e:dc:97:12:65:64",
       "8e:dc:97:12:65:2b", "88:dc:97:12:64:c4", "88:dc:97:12:62:c6", "8e:dc:97:12:62:cf",
       "b4:5d:50:d7:e9:51", "b4:5d:50:d7:e9:50", "88:dc:97:12:62:c7", "8e:dc:97:12:65:22",
       "88:dc:97:12:65:57", "88:dc:97:12:64:82", "88:dc:97:12:64:83", "8e:dc:97:12:62:c7",
       "8e:dc:97:12:62:c6", "8e:dc:97:12:64:82", "8e:dc:97:12:64:83", "88:dc:97:12:65:58",
       "88:dc:97:12:65:2b", "88:dc:97:12:65:2a", "8e:dc:97:12:64:c4", "88:dc:97:12:62:d0",
       "b4:5d:50:d7:e9:40", "8e:dc:97:12:65:2a", "8e:dc:97:12:62:d0", "88:dc:97:12:65:22",
       "88:dc:97:12:65:21", "8e:dc:97:12:65:58", "8e:dc:97:12:65:57", "b4:5d:50:d7:e9:41",
       "88:dc:97:12:65:64", "88:dc:97:12:65:63"
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

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rssi': wifiData}),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        List coordinates = responseData['coordinates'];
        int rp = responseData['rp'];

        updatePosition(coordinates, rp);
      } else {
        print("Gửi dữ liệu thất bại: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi khi quét và gửi dữ liệu Wi-Fi: $e");
    }
  }
}
