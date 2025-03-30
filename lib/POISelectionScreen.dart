import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
import 'dart:convert';

class POISelectionScreen {
  final MapController mapController = MapController();
  double currentZoom = 18.0;
  String? startPOI;
  String? endPOI;

  List<Map<String, dynamic>> poiList = [];
  List<LatLng> selectedRoute = [];
  late Map<String, List<Map<String, dynamic>>> graph;
  List<List<LatLng>> walls = [];
  final GeoJsonParser geoJsonParser = GeoJsonParser();

  final List<Map<String, dynamic>> wallList = [
    {
      "coordinates": [
        LatLng(11.957244112442652, 108.444839594372198),
        LatLng(11.957247003157194, 108.444855550437865),
        LatLng(11.957303661155976, 108.444830729891251),
        LatLng(11.957314645868653, 108.444865596849596),
        LatLng(11.957250472014604, 108.444891599326994),
        LatLng(11.957315802154174, 108.444865005884196),
        LatLng(11.957344131147845, 108.444932375939302),
        LatLng(11.957348756289385, 108.444947150074213),
        LatLng(11.957369569425346, 108.444954241658948),
        LatLng(11.957381132277966, 108.444930012077748),
        LatLng(11.957370147567985, 108.444954832624362),
        LatLng(11.957355694001548, 108.444993245375073),
        LatLng(11.957307708155437, 108.445010383371581),
        LatLng(11.957355115858878, 108.444993245375073),
        LatLng(11.957371303853268, 108.444953059728178),
        LatLng(11.957348178146693, 108.444946559108814),
        LatLng(11.957315802154174, 108.444864414918783),
        LatLng(11.957304239298763, 108.444830138925866),
        LatLng(11.957245846871384, 108.444855550437865),
        LatLng(11.957244112442652, 108.444840185337583),
        LatLng(11.957163750566028, 108.444870324572747),
        LatLng(11.95712385869035, 108.444889826430824),
        LatLng(11.957064888080751, 108.444916419873621),
        LatLng(11.957068356940493, 108.444931784973917),
        LatLng(11.957070235906169, 108.444932375939302),
        LatLng(11.95702759783569, 108.444950991349288),
        LatLng(11.957040316989618, 108.444982312515265),
        LatLng(11.957091049063548, 108.444960446795605),
        LatLng(11.957101455641643, 108.444989404099999),
        LatLng(11.957091627206786, 108.444961037761004),
        LatLng(11.957042629562995, 108.444981721549865),
        LatLng(11.957070958585271, 108.445049682570385),
        LatLng(11.957055348716223, 108.44508395856333),
        LatLng(11.957017769398147, 108.445069184428391),
        LatLng(11.957002737669454, 108.445105824282933),
        LatLng(11.957038582559569, 108.445124735175597),
        LatLng(11.95709292802907, 108.445107006213718),
        LatLng(11.957099865747795, 108.445134190621928),
        LatLng(11.957378530636161, 108.445017179473581),
        LatLng(11.957099865747795, 108.445134190621928)
      ]
    },
    {
      "coordinates": [
        LatLng(11.957230381548149, 108.44489957735982),
        LatLng(11.957239631835044, 108.444932671421952),
        LatLng(11.957209568401481, 108.444946854591478),
        LatLng(11.95720494325756, 108.444926761768002)
      ]
    },
    {
      "coordinates": [
        LatLng(11.957144527307822, 108.444952764245443),
        LatLng(11.95715001966745, 108.444971379655385),
        LatLng(11.95712197972504, 108.444981721549823),
        LatLng(11.95711128407614, 108.444952173280029)
      ]
    },
    {
      "coordinates": [
        LatLng(11.957306985476951, 108.444946854591436),
        LatLng(11.957317392046738, 108.444988222169158),
        LatLng(11.957279234622233, 108.445004769200239),
        LatLng(11.957282703479224, 108.445023680092888)
      ]
    },
    {
      "coordinates": [
        LatLng(11.957100010283591, 108.445039045193184),
        LatLng(11.957116198293249, 108.445079230840108),
        LatLng(11.957141636592182, 108.445065047670582),
        LatLng(11.957147418023427, 108.445078048909323)
      ]
    },
    {
      "coordinates": [
        LatLng(11.957093072564868, 108.445107597179089),
        LatLng(11.957132964445087, 108.44508986821721)
      ]
    }
  ];

  POISelectionScreen() {
    _loadWallsFromWallList();
    _loadPOIData();
    loadGeoJson().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnPOIs());
    });
  }

  List<String> directions = [];

  void _calculateDirections() {
    directions.clear();
    if (selectedRoute.length < 2) return; // Cần ít nhất 2 điểm để có hướng dẫn

    // Duyệt qua từng cặp điểm liên tiếp để xác định hướng
    for (int i = 0; i < selectedRoute.length - 1; i++) {
      if (i == 0 || selectedRoute.length < 3) {
        // Nếu chỉ có 2 điểm, chỉ cần "Đi thẳng" đến đích
        directions.add("Đi thẳng đến đích");
      } else {
        // Tính hướng dựa trên 3 điểm (trừ đoạn cuối)
        String direction = _getDirection(selectedRoute[i - 1], selectedRoute[i], selectedRoute[i + 1]);
        directions.add(direction);
      }
    }

    // Đảm bảo hướng dẫn cuối cùng là "Đến đích"
    if (directions.isNotEmpty && directions.last != "Đi thẳng đến đích") {
      directions.add("Đi thẳng đến đích");
    }
  }

  String _getDirection(LatLng p1, LatLng p2, LatLng p3) {
    double v1x = p2.longitude - p1.longitude;
    double v1y = p2.latitude - p1.latitude;
    double v2x = p3.longitude - p2.longitude;
    double v2y = p3.latitude - p2.latitude;

    double crossProduct = v1x * v2y - v1y * v2x;
    double dotProduct = v1x * v2x + v1y * v2y;
    double mag1 = sqrt(v1x * v1x + v1y * v1y);
    double mag2 = sqrt(v2x * v2x + v2y * v2y);
    double angle = acos(dotProduct / (mag1 * mag2)) * 180 / pi;

    if (angle < 10) {
      return "Đi thẳng";
    } else if (crossProduct > 0) {
      return "Rẽ trái";
    } else {
      return "Rẽ phải";
    }
  }

  void _showDirections(BuildContext context) {
    if (directions.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hướng dẫn đường đi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: directions.asMap().entries.map((entry) {
              int index = entry.key + 1;
              String direction = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text("$index. $direction"),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> loadGeoJson() async {
    List<String> geoJsonFiles = [
      "assets/geojson/Room.geojson",
      "assets/geojson/Wall.geojson",
      "assets/geojson/Hallways.geojson",
      "assets/geojson/Doors.geojson",
      "assets/geojson/POI.geojson",
    ];

    for (String path in geoJsonFiles) {
      try {
        String geoJsonData = await rootBundle.loadString(path);
        final geoJson = jsonDecode(geoJsonData);
        if (geoJson['features'] is List) {
          for (var feature in geoJson['features']) {
            final properties = feature['properties'];
            final geometry = feature['geometry'];

            if (geometry['type'] == 'Point' && path == "assets/geojson/POI.geojson") {
              final coordinates = geometry['coordinates'];
              final lat = coordinates[1];
              final lng = coordinates[0];

              geoJsonParser.markers.add(
                Marker(
                  point: LatLng(lat, lng),
                  child: Column(
                    children: [
                      Text(
                        properties['Name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          backgroundColor: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            } else if (geometry['type'] == 'Polygon') {
              final coordinates = geometry['coordinates'][0];
              final points = coordinates.map<LatLng>((coord) {
                return LatLng(coord[1], coord[0]);
              }).toList();

              Color fillColor;
              if (path == "assets/geojson/Room.geojson") {
                fillColor = Colors.blue.withOpacity(0.3);
              } else if (path == "assets/geojson/Wall.geojson") {
                fillColor = Colors.grey.withOpacity(0.3);
              } else if (path == "assets/geojson/Hallways.geojson") {
                fillColor = Colors.green.withOpacity(0.3);
              } else {
                fillColor = Colors.transparent;
              }

              geoJsonParser.polygons.add(
                Polygon(
                  points: points,
                  color: fillColor,
                  borderColor: fillColor.withOpacity(0.8),
                  borderStrokeWidth: 2,
                  label: properties['Name'],
                ),
              );
            }
          }
        }
        print("Loaded GeoJSON: $path");
      } catch (e) {
        print("Lỗi load GeoJSON từ $path: $e");
      }
    }
  }

  void _focusOnPOIs() {
    if (geoJsonParser.markers.isNotEmpty) {
      final latitudes = geoJsonParser.markers.map((m) => m.point.latitude).toList();
      final longitudes = geoJsonParser.markers.map((m) => m.point.longitude).toList();

      final bounds = LatLngBounds(
        LatLng(latitudes.reduce((a, b) => a < b ? a : b),
            longitudes.reduce((a, b) => a < b ? a : b)),
        LatLng(latitudes.reduce((a, b) => a > b ? a : b),
            longitudes.reduce((a, b) => a > b ? a : b)),
      );

      mapController.fitBounds(bounds, options: FitBoundsOptions(padding: EdgeInsets.all(50)));
    }
  }

  void _loadWallsFromWallList() {
    walls = wallList.map((wall) {
      return wall['coordinates'] as List<LatLng>;
    }).toList();
  }

  Future<void> _loadPOIData() async {
    try {
      final poiData = await rootBundle.loadString('assets/geojson/POI.geojson');
      final poiJson = json.decode(poiData);

      poiList = (poiJson['features'] as List).map((feature) {
        final properties = feature['properties'];
        final coordinates = feature['geometry']['coordinates'];
        return {
          "name": properties['Name'] ?? 'Unknown',
          "rp": properties['RP'] ?? 'Unknown',
          "coordinates": LatLng(coordinates[1], coordinates[0]),
        };
      }).toList();

      graph = _generateGraph();
    } catch (e) {
      print("Error loading POI data: $e");
    }
  }

  Map<String, List<Map<String, dynamic>>> _generateGraph() {
    Map<String, List<Map<String, dynamic>>> generatedGraph = {};

    for (var poi in poiList) {
      String poiRP = poi["rp"];
      generatedGraph[poiRP] = [];
      LatLng coordinates = poi["coordinates"];

      for (var otherPoi in poiList) {
        if (otherPoi == poi) continue;
        String otherRP = otherPoi["rp"];
        LatLng otherCoordinates = otherPoi["coordinates"];

        if (!_isPathBlocked(coordinates, otherCoordinates)) {
          double distance = _calculateDistance(coordinates, otherCoordinates);
          generatedGraph[poiRP]!.add({"rp": otherRP, "distance": distance});
        }
      }
    }
    return generatedGraph;
  }

  bool _isPathBlocked(LatLng start, LatLng end) {
    for (var wall in walls) {
      for (int i = 0; i < wall.length - 1; i++) {
        if (_doLinesIntersect(start, end, wall[i], wall[i + 1])) {
          return true;
        }
      }
    }
    return false;
  }

  bool _doLinesIntersect(LatLng p1, LatLng q1, LatLng p2, LatLng q2) {
    int orientation(LatLng a, LatLng b, LatLng c) {
      double value = (b.latitude - a.latitude) * (c.longitude - b.longitude) -
          (b.longitude - a.longitude) * (c.latitude - b.latitude);
      if (value == 0) return 0;
      return (value > 0) ? 1 : 2;
    }

    bool onSegment(LatLng a, LatLng b, LatLng c) {
      return b.latitude <= max(a.latitude, c.latitude) &&
          b.latitude >= min(a.latitude, c.latitude) &&
          b.longitude <= max(a.longitude, c.longitude) &&
          b.longitude >= min(a.longitude, c.longitude);
    }

    int o1 = orientation(p1, q1, p2);
    int o2 = orientation(p1, q1, q2);
    int o3 = orientation(p2, q2, p1);
    int o4 = orientation(p2, q2, q1);

    if (o1 != o2 && o3 != o4) return true;

    if (o1 == 0 && onSegment(p1, p2, q1)) return true;
    if (o2 == 0 && onSegment(p1, q2, q1)) return true;
    if (o3 == 0 && onSegment(p2, p1, q2)) return true;
    if (o4 == 0 && onSegment(p2, q1, q2)) return true;

    return false;
  }

  List<LatLng> _findShortestPath(String start, String end) {
    if (!graph.containsKey(start) || !graph.containsKey(end)) {
      print("Start or end POI not found in the graph.");
      return [];
    }

    final Map<String, double> distances = {};
    final Map<String, String?> previous = {};
    final List<String> unvisited = [];

    for (var node in graph.keys) {
      distances[node] = double.infinity;
      previous[node] = null;
      unvisited.add(node);
    }
    distances[start] = 0;

    while (unvisited.isNotEmpty) {
      unvisited.sort((a, b) => distances[a]!.compareTo(distances[b]!));
      final current = unvisited.removeAt(0);

      if (current == end) break;

      for (var neighbor in graph[current]!) {
        final newDist = distances[current]! + neighbor['distance'];
        if (newDist < distances[neighbor['rp']]!) {
          distances[neighbor['rp']] = newDist;
          previous[neighbor['rp']] = current;
        }
      }
    }

    final path = <String>[];
    var current = end;
    while (current.isNotEmpty) {
      path.insert(0, current);
      current = previous[current] ?? '';
    }

    return path.map((rp) {
      return poiList.firstWhere((poi) => poi['rp'] == rp)['coordinates'] as LatLng;
    }).toList();
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371;
    double dLat = (point2.latitude - point1.latitude) * (pi / 180);
    double dLon = (point2.longitude - point1.longitude) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(point1.latitude * (pi / 180)) *
            cos(point2.latitude * (pi / 180)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c * 1000;
  }

  void _drawRoute(BuildContext context, VoidCallback setStateCallback) {
    if (startPOI != null && endPOI != null) {
      selectedRoute = _findShortestPath(startPOI!, endPOI!);
      if (selectedRoute.isNotEmpty) {
        _calculateDirections();
        _showDirections(context); // Hiển thị tất cả hướng dẫn trong 1 pop-up
      }
    }
  }

  void _onPOITap(String rp, BuildContext context, VoidCallback setStateCallback) {
    if (startPOI == null) {
      startPOI = rp;
    } else if (endPOI == null) {
      endPOI = rp;
      _drawRoute(context, setStateCallback);
    } else {
      startPOI = rp;
      endPOI = null;
      selectedRoute = [];
      directions.clear();
    }
    setStateCallback();
  }

  Widget buildMapSection(BuildContext context, VoidCallback setStateCallback) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: LatLng(11.957103446948263, 108.4451276943349),
        zoom: currentZoom,
        onPositionChanged: (position, hasGesture) {
          if (position.zoom != null) {
            currentZoom = position.zoom!;
            setStateCallback();
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        if (geoJsonParser.polygons.isNotEmpty)
          PolygonLayer(polygons: geoJsonParser.polygons),
        if (geoJsonParser.polylines.isNotEmpty)
          PolylineLayer(polylines: geoJsonParser.polylines),
        if (geoJsonParser.markers.isNotEmpty)
          MarkerLayer(
            markers: geoJsonParser.markers.map((marker) {
              final showName = currentZoom >= 20;
              return Marker(
                width: 80.0,
                height: 80.0,
                point: marker.point,
                child: Column(
                  children: [
                    if (showName)
                      Text(
                        (marker.child as Column).children[0] is Text
                            ? ((marker.child as Column).children[0] as Text).data ?? "POI"
                            : "POI",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          backgroundColor: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 20,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        PolylineLayer(
          polylines: walls.map((wall) {
            return Polyline(
              points: wall,
              color: Colors.black,
              strokeWidth: 2.0,
            );
          }).toList(),
        ),
        MarkerLayer(
          markers: poiList.map((poi) {
            return Marker(
              point: poi['coordinates'] as LatLng,
              width: 80.0,
              height: 80.0,
              child: GestureDetector(
                onTap: () => _onPOITap(poi['rp'] as String, context, setStateCallback),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        poi['name'] ?? "Unknown", // Display Name only
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.location_on,
                      color: (poi['rp'] == startPOI)
                          ? Colors.green
                          : (poi['rp'] == endPOI)
                              ? Colors.blue
                              : Colors.red,
                      size: 30,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
    );
  }
}