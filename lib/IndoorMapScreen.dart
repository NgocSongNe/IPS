import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class POISelection extends StatefulWidget {
  POISelection({Key? key}) : super(key: key);

  @override
  _POISelectionState createState() => _POISelectionState();
}

class _POISelectionState extends State<POISelection> {
  List<Marker> markers = [];
  double currentZoom = 13.0; // Default zoom level

  @override
  void initState() {
    super.initState();
    fetchPOIData();
  }

  Future<void> fetchPOIData() async {
    try {
     
      final response =
          await http.get(Uri.parse("http://localhost:5000/geojson/POI"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          markers = _createMarkers(data);
        });
      } else {
        throw Exception("🚨 Không thể tải dữ liệu POI!");
      }
    } catch (e) {
      print("❌ Lỗi tải dữ liệu: $e");
    }
  }

  List<Marker> _createMarkers(Map<String, dynamic> data) {
    List<Marker> markerList = [];

    for (var feature in data["features"]) {
      var coordinates = feature["geometry"]["coordinates"];
      markerList.add(
        Marker(
          width: 40.0,
          height: 40.0,
          point:
              LatLng(coordinates[1], coordinates[0]), // (latitude, longitude)
          child: Icon(Icons.location_pin, color: Colors.red, size: 40),
        ),
      );
    }

    return markerList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("POI Selection")),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(10.7769, 106.7009),
          zoom: currentZoom,
          onPositionChanged: (position, hasGesture) {
            if (position.zoom != null) {
              setState(() {
                currentZoom = position.zoom!; // Update the current zoom level
              });
            }
          },
        ),
        
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
