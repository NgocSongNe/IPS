import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://localhost:5000"; // Nếu chạy trên Android Emulator, đổi thành "http://10.0.2.2:5000"

  Future<Map<String, dynamic>> fetchGeoJSON(String collectionName) async {
    final response = await http.get(Uri.parse('$baseUrl/geojson/$collectionName'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi khi tải dữ liệu GeoJSON');
    }
  }
}
