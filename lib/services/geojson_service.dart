// lib/services/geojson_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeoJsonService {
  Future<Map<String, dynamic>> loadGeoJson(String endpoint) async {
    final response = await http.get(Uri.parse("http://10.10.67.90:8765$endpoint"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load GeoJSON data");
    }
  }
}
