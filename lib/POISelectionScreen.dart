import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class POISelectionScreen extends StatefulWidget {
  @override
  _POISelectionScreenState createState() => _POISelectionScreenState();
}

class _POISelectionScreenState extends State<POISelectionScreen> {
  String? startPOI;
  String? endPOI;

  final List<Map<String, dynamic>> poiList = [
    {
      "name": "TV3,4",
      "coordinates": LatLng(11.957103446948263, 108.4451276943349)
    },
    {
      "name": "Cửa ra vào",
      "coordinates": LatLng(11.95722012378778, 108.44507513707596)
    },
    // Add more POIs here...
  ];

  List<LatLng> selectedRoute = [];

  void _drawRoute() {
    if (startPOI != null && endPOI != null) {
      final start =
          poiList.firstWhere((poi) => poi['name'] == startPOI)['coordinates'];
      final end =
          poiList.firstWhere((poi) => poi['name'] == endPOI)['coordinates'];
      setState(() {
        selectedRoute = [start, end];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chọn Địa Điểm")),
      body: Column(
        children: [
          DropdownButton<String>(
            hint: Text("Chọn điểm bắt đầu"),
            value: startPOI,
            onChanged: (value) {
              setState(() {
                startPOI = value;
              });
            },
            items: poiList.map((poi) {
              return DropdownMenuItem<String>(
                value: poi['name'] as String,
                child: Text(poi['name'] as String),
              );
            }).toList(),
          ),
          DropdownButton<String>(
            hint: Text("Chọn điểm kết thúc"),
            value: endPOI,
            onChanged: (value) {
              setState(() {
                endPOI = value;
              });
            },
            items: poiList.map((poi) {
              return DropdownMenuItem<String>(
                value: poi['name'] as String,
                child: Text(poi['name'] as String),
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed: _drawRoute,
            child: Text("Vẽ đường"),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(11.957103446948263, 108.4451276943349),
                zoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                if (selectedRoute.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: selectedRoute,
                        color: Colors.red,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
