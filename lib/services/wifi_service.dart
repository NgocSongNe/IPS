// wifi_service.dart
import 'package:wifi_scan/wifi_scan.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WifiService {
  Future<void> sendWiFiDataToServer(List<WiFiAccessPoint> wifiNetworks) async {
    final url = Uri.parse('http://10.10.67.90:8765/predict'); // URL server Node.js

    try {
      if (wifiNetworks.isEmpty) {
        print("❌ Không tìm thấy mạng Wi-Fi");
        return;
      }

      Map<String, int> macToRssi = {};
      for (var wifi in wifiNetworks) {
        macToRssi[wifi.bssid] = wifi.level;
      }

      List<int> wifiData = [];
      macToRssi.forEach((mac, rssi) {
        wifiData.add(rssi);
      });

      Map<String, dynamic> dataToSend = {'rssi': wifiData};

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dataToSend),
      );

      if (response.statusCode == 200) {
        print("✅ Dữ liệu đã được gửi thành công");
      } else {
        print("❌ Gửi dữ liệu thất bại");
      }
    } catch (e) {
      print("❌ Lỗi khi quét và gửi dữ liệu Wi-Fi: $e");
    }
  }
}
