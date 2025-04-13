import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class POISelectionScreen {
  final MapController mapController = MapController();
  double currentZoom = 20.0;
  String? startPOI;
  String? endPOI;
  double? pathDistance;

  List<Map<String, dynamic>> poiList = [];
  List<LatLng> selectedRoute = [];
  late Map<String, List<Map<String, dynamic>>> graph;
  List<List<LatLng>> walls = [];
  List<List<LatLng>> hallways = [];
  List<LatLng> waypoints = [];
  final GeoJsonParser geoJsonParser = GeoJsonParser();

  List<String> directions = [];
  List<double> segmentDistances = [];
  String userPositionRP = "userPositionContainer"; // Changed from userPosition
  LatLng userPositionCoordinates; // Will be set via constructor
  String? selectedMarkerRP;
  String? secondSelectedMarkerRP;
  final BuildContext context; // For accessing DefaultAssetBundle

  // Mapping from RP to image folder names
  final Map<String, String> rpToFolderMap = {
    "1": "tv3_4",
    "2": "cua_ra_vao",
    "3": "hoi_truong_thu_vien",
    "4": "cau_thang",
    "5": "cau_thang",
    "6": "cau_thang",
    "7": "cau_thang",
    "8": "khu_vuc_tu_hoc",
    "9": "can_tin",
    "10": "cau_thang",
    "11": "cau_thang",
    "12": "khu_vuc_tu_hoc",
    "13": "khu_vuc_tu_hoc",
    "14": "khu_vuc_tu_hoc",
    "15": "khu_vuc_tu_hoc",
    "16": "hanh_lang",
    "17": "hanh_lang",
    "18": "khu_vuc_tu_hoc",
    "19": "cau_thang",
    "20": "cau_thang",
    "21": "cau_thang",
    "22": "khu_vuc_doc",
    "23": "khu_vuc_tu_hoc",
    "24": "khu_vuc_tu_hoc",
    "25": "khu_vuc_doc",
    "26": "khu_vuc_doc",
    "27": "khu_vuc_doc",
    "28": "cau_thang",
    "29": "cau_thang",
    "30": "khu_vuc_doc",
    "31": "khu_vuc_doc",
    "32": "cau_thang",
    "33": "cau_thang_tang_2",
    "34": "cua_ra_vao",
    "35": "khu_vuc_tu_hoc",
    "36": "ban_thu_thu",
    "37": "ban_thu_thu",
    "38": "khu_vuc_tu_hoc",
    "39": "phong_tap_chi",
    "40": "cau_thang_tang_2",
  };

  POISelectionScreen({
    required this.userPositionCoordinates,
    required this.context,
  }) {
    _loadWallsFromAPI();
    _loadPOIData();
    loadGeoJson().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnPOIs());
    });
  }

  Future<List<String>> _getImagesFromFolder(String folderName) async {
    try {
      final manifestContent =
          await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final imagePaths = manifestMap.keys
          .where((String key) => key.startsWith('assets/images/$folderName/'))
          .toList();
      return imagePaths;
    } catch (e) {
      print("Error loading images for folder $folderName: $e");
      return [];
    }
  }

  void _calculateDirections() {
    directions.clear();
    segmentDistances.clear();
    if (selectedRoute.length < 2) return;

    for (int i = 0; i < selectedRoute.length - 1; i++) {
      double segmentDistance = _calculateDistance(selectedRoute[i], selectedRoute[i + 1]);
      segmentDistances.add(segmentDistance);

      if (i == 0 || selectedRoute.length < 3) {
        directions.add("Đi thẳng đến đích");
      } else {
        String direction = _getDirection(
            selectedRoute[i - 1], selectedRoute[i], selectedRoute[i + 1]);
        directions.add(direction);
      }
    }

    if (directions.isNotEmpty && directions.last != "Đi thẳng đến đích") {
      directions.add("Đi thẳng đến đích");
      if (selectedRoute.length > 1) {
        segmentDistances.add(_calculateDistance(
            selectedRoute[selectedRoute.length - 2], selectedRoute.last));
      }
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
    if (directions.isEmpty && pathDistance == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hướng dẫn đường đi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pathDistance != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Tổng khoảng cách: ${pathDistance!.toStringAsFixed(2)} mét",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ...directions.asMap().entries.map((entry) {
                int index = entry.key + 1;
                String direction = entry.value;
                String distanceText = entry.key < segmentDistances.length
                    ? " (${segmentDistances[entry.key].toStringAsFixed(2)} mét)"
                    : "";
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text("$index. $direction$distanceText"),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> loadGeoJson() async {
    List<String> geoJsonEndpoints = [
      "/geojson/Room",
      "/geojson/Wall",
      "/geojson/Hallways",
      "/geojson/Doors",
      "/geojson/POI",
    ];

    for (String endpoint in geoJsonEndpoints) {
      try {
        final response =
            await http.get(Uri.parse("http://192.168.2.35:8765$endpoint"));
        if (response.statusCode == 200) {
          final geoJson = jsonDecode(response.body);
          if (geoJson['features'] is List) {
            for (var feature in geoJson['features']) {
              final properties = feature['properties'];
              final geometry = feature['geometry'];

              if (geometry['type'] == 'Point' && endpoint == "/geojson/POI") {
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
                if (endpoint == "/geojson/Room") {
                  fillColor = Colors.blue.withOpacity(0.3);
                } else if (endpoint == "/geojson/Wall") {
                  fillColor = Colors.grey.withOpacity(0.3);
                  walls.add(points);
                } else if (endpoint == "/geojson/Hallways") {
                  fillColor = Colors.green.withOpacity(0.3);
                  hallways.add(points);
                  waypoints.addAll(points);
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
          print("Loaded GeoJSON from $endpoint");
        } else {
          print(
              "Failed to load GeoJSON from $endpoint: ${response.statusCode}");
        }
      } catch (e) {
        print("Error loading GeoJSON from $endpoint: $e");
      }
    }
  }

  void _focusOnPOIs() {
    if (geoJsonParser.markers.isNotEmpty) {
      final latitudes =
          geoJsonParser.markers.map((m) => m.point.latitude).toList();
      final longitudes =
          geoJsonParser.markers.map((m) => m.point.longitude).toList();

      final bounds = LatLngBounds(
        LatLng(latitudes.reduce((a, b) => a < b ? a : b),
            longitudes.reduce((a, b) => a < b ? a : b)),
        LatLng(latitudes.reduce((a, b) => a > b ? a : b),
            longitudes.reduce((a, b) => a > b ? a : b)),
      );

      mapController.fitBounds(bounds,
          options: FitBoundsOptions(padding: EdgeInsets.all(50)));
    }
  }

  Future<void> _loadWallsFromAPI() async {
    try {
      final response =
          await http.get(Uri.parse("http://192.168.2.35:8765/geojson/Paths"));
      if (response.statusCode == 200) {
        final pathsJson = json.decode(response.body);
        walls = (pathsJson['features'] as List).map<List<LatLng>>((feature) {
          final coordinates = feature['geometry']['coordinates'];
          return coordinates.map<LatLng>((coord) {
            return LatLng(coord[1], coord[0]);
          }).toList();
        }).toList();
      } else {
        print("Failed to load walls data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error loading walls data: $e");
    }
  }

  Future<void> _loadPOIData() async {
    try {
      final response =
          await http.get(Uri.parse("http://192.168.2.35:8765/geojson/POI"));
      if (response.statusCode == 200) {
        final poiJson = json.decode(response.body);

        poiList = [];
        for (var feature in poiJson['features']) {
          final properties = feature['properties'];
          final coordinates = feature['geometry']['coordinates'];
          String rp = properties['RP'] ?? 'unknown';
          String folderName = rpToFolderMap[rp] ?? 'unknown';
          List<String> images = await _getImagesFromFolder(folderName);

          poiList.add({
            "name": properties['Name'] ?? 'Unknown',
            "rp": rp,
            "coordinates": LatLng(coordinates[1], coordinates[0]),
            "description": properties['Description'] ?? 'Không có mô tả',
            "images": images,
          });
        }

        // Add user position to poiList
        poiList.add({
          "name": "User Position",
          "rp": userPositionRP,
          "coordinates": userPositionCoordinates,
          "description": "Vị trí hiện tại của bạn",
          "images": <String>[],
        });

        for (int i = 0; i < waypoints.length; i++) {
          poiList.add({
            "name": "Waypoint $i",
            "rp": "wp_$i",
            "coordinates": waypoints[i],
            "description": "Điểm trung gian",
            "images": <String>[],
          });
        }

        graph = _generateGraph();
      } else {
        print("Failed to load POI data: ${response.statusCode}");
      }
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

        if (_isPathInHallway(coordinates, otherCoordinates) &&
            !_isPathBlocked(coordinates, otherCoordinates)) {
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

  bool _isPathInHallway(LatLng start, LatLng end) {
    if (hallways.isEmpty) return true;

    for (var hallway in hallways) {
      if (_isPointInPolygon(start, hallway) && _isPointInPolygon(end, hallway)) {
        return true;
      }
    }
    return false;
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int j = polygon.length - 1;
    bool inside = false;

    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].latitude > point.latitude) !=
              (polygon[j].latitude > point.latitude)) &&
          (point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                      (point.latitude - polygon[i].latitude) /
                      (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
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
    while (current.isNotEmpty && previous[current] != null) {
      path.insert(0, current);
      current = previous[current]!;
    }
    if (path.isNotEmpty && distances[end] != double.infinity) {
      path.insert(0, start);
    } else {
      print("No path found from $start to $end");
      return [];
    }

    return path.map((rp) {
      return poiList.firstWhere((poi) => poi['rp'] == rp)['coordinates']
          as LatLng;
    }).toList();
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371;
    double dLat = (point2.latitude - point1.latitude) * (pi / 180);
    double dLon = (point2.longitude - point1.longitude) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(point1.latitude * (pi / 180)) *
            cos(point2.latitude * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c * 1000;
  }

  double _calculatePathDistance(List<LatLng> route) {
    if (route.length < 2) return 0.0;
    double totalDistance = 0.0;
    for (var i = 0; i < route.length - 1; i++) {
      totalDistance += _calculateDistance(route[i], route[i + 1]);
    }
    return totalDistance;
  }

  void _drawRoute(BuildContext context, VoidCallback setStateCallback) {
    if (startPOI != null && endPOI != null) {
      selectedRoute = _findShortestPath(startPOI!, endPOI!);
      if (selectedRoute.isNotEmpty) {
        pathDistance = _calculatePathDistance(selectedRoute);
        _calculateDirections();
        _showDirections(context);
        setStateCallback();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy đường đi giữa hai điểm")),
        );
      }
    }
  }

  void _onPOITap(
      String rp, BuildContext context, VoidCallback setStateCallback) {
    var poi = poiList.firstWhere(
      (poi) => poi['rp'] == rp,
      orElse: () => {
        "name": "Không tìm thấy",
        "description": "Không tìm thấy POI với RP: $rp",
        "images": <String>[],
      },
    );

    if (poi['name'] == "Không tìm thấy") {
      print("Không tìm thấy POI với RP: $rp");
      return;
    }

    if (startPOI == null) {
      startPOI = rp;
      selectedMarkerRP = rp;
    } else if (endPOI == null && rp != startPOI) {
      endPOI = rp;
      secondSelectedMarkerRP = rp;
      _drawRoute(context, setStateCallback);
    } else {
      startPOI = rp;
      endPOI = null;
      selectedMarkerRP = rp;
      secondSelectedMarkerRP = null;
      selectedRoute = [];
      directions.clear();
      segmentDistances.clear();
      pathDistance = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    poi['name'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                poi['description'] ?? 'Không có mô tả',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      startPOI = rp;
                      selectedMarkerRP = rp;
                      if (endPOI != null && startPOI != endPOI) {
                        _drawRoute(context, setStateCallback);
                      }
                      setStateCallback();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: Text(
                      "Bắt đầu",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      startPOI = userPositionRP;
                      selectedMarkerRP = userPositionRP;
                      endPOI = rp;
                      secondSelectedMarkerRP = rp;
                      _drawRoute(context, setStateCallback);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: Text(
                      "Tìm đường",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: poi['images'] != null && (poi['images'] as List).isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (poi['images'] as List).length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                (poi['images'] as List)[index],
                                width: 150,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 150,
                                    height: 100,
                                    color: Colors.grey,
                                    child: const Center(
                                      child: Icon(Icons.error, color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(child: Text("Không có hình ảnh")),
              ),
            ],
          ),
        );
      },
    );

    setStateCallback();
  }

  Widget buildMapSection(BuildContext context, VoidCallback setStateCallback) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            center: userPositionCoordinates,
            zoom: currentZoom,
            minZoom: 5.0,
            maxZoom: 22.0,
            interactiveFlags: InteractiveFlag.all,
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
            MarkerLayer(
              rotate: true,
              markers: [
                ...poiList.map((poi) {
                  if (poi['rp'] == userPositionRP) return null;
                  final isSelected = poi['rp'] == selectedMarkerRP ||
                      poi['rp'] == secondSelectedMarkerRP;
                  return Marker(
                    point: poi['coordinates'] as LatLng,
                    width: isSelected ? 80.0 : 60.0,
                    height: isSelected ? 80.0 : 60.0,
                    child: GestureDetector(
                      onTap: () {
                        _onPOITap(poi['rp'] as String, context, setStateCallback);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              poi['name'] ?? "Unknown",
                              style: TextStyle(
                                fontSize: isSelected ? 10 : 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          isSelected
                              ? Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 30,
                                )
                              : Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withOpacity(0.6),
                                    border: Border.all(
                                      color: Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  );
                }).where((marker) => marker != null).cast<Marker>(),
                Marker(
                  point: userPositionCoordinates,
                  width: selectedMarkerRP == userPositionRP ? 80.0 : 60.0,
                  height: selectedMarkerRP == userPositionRP ? 80.0 : 60.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: selectedMarkerRP == userPositionRP
                              ? Colors.green.withOpacity(0.7)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          "User",
                          style: TextStyle(
                            fontSize:
                                selectedMarkerRP == userPositionRP ? 12 : 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.person_pin_circle,
                        color: selectedMarkerRP == userPositionRP
                            ? Colors.red
                            : Colors.blue,
                        size: 32,
                      ),
                    ],
                  ),
                ),
              ],
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
        if (pathDistance != null)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                "Tổng khoảng cách: ${pathDistance!.toStringAsFixed(2)} mét",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}