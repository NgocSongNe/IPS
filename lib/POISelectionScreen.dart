import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

class POISelectionScreen {
  final MapController mapController = MapController();
  double currentZoom = 20.0;
  String? startPOI;
  String? endPOI;
  LatLng userPositionCoordinates;
  double? pathDistance;
  List<Map<String, dynamic>> poiList = [];
  List<LatLng> selectedRoute = []; // Đường dẫn đã làm mịn để vẽ nét đứt
  List<LatLng> originalRoute = []; // Đường dẫn gốc để tính hướng dẫn
  late Map<String, List<Map<String, dynamic>>> graph;
  List<List<LatLng>> walls = [];
  List<List<LatLng>> hallways = [];
  List<LatLng> waypoints = [];
  final GeoJsonParser geoJsonParser = GeoJsonParser();

  String userPositionRP = "userPosition";
  List<String> directions = [];
  List<double> segmentDistances = [];

  String? selectedMarkerRP;
  String? secondSelectedMarkerRP;

  final BuildContext context;
  final FlutterTts _flutterTts = FlutterTts();

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

  POISelectionScreen({required this.userPositionCoordinates, required this.context}) {
    _loadWallsFromAPI();
    _loadPOIData();
    loadGeoJson().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnPOIs());
    });
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speakDirections() async {
    if (directions.isEmpty) return;
    for (int i = 0; i < directions.length; i++) {
      String direction = directions[i];
      String distanceText = i < segmentDistances.length
          ? " ${segmentDistances[i].toStringAsFixed(2)} mét"
          : "";
      String textToSpeak = "$direction$distanceText";
      await _flutterTts.speak(textToSpeak);
      await Future.delayed(Duration(seconds: 2));
    }
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
    if (originalRoute.length < 2) {
      print("Original route has less than 2 points, cannot calculate directions.");
      return;
    }

    for (int i = 0; i < originalRoute.length - 1; i++) {
      double segmentDistance = _calculateDistance(originalRoute[i], originalRoute[i + 1]);
      segmentDistances.add(segmentDistance);

      if (i == 0 || originalRoute.length < 3) {
        directions.add("Đi thẳng đến đích");
      } else {
        String direction = _getDirection(
            originalRoute[i - 1], originalRoute[i], originalRoute[i + 1]);
        directions.add(direction);
      }
    }

    if (directions.isNotEmpty && directions.last != "Đi thẳng đến đích") {
      directions.add("Đi thẳng đến đích");
      if (originalRoute.length > 1) {
        segmentDistances.add(_calculateDistance(
            originalRoute[originalRoute.length - 2], originalRoute.last));
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hướng dẫn đường đi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Tổng khoảng cách: ${pathDistance != null ? pathDistance!.toStringAsFixed(2) : '0.00'} mét",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (directions.isNotEmpty)
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
                }).toList()
              else
                const Text("Không có hướng dẫn nào."),
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
            await http.get(Uri.parse("https://trannguyenanhminh.click$endpoint"));
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
          print("Failed to load GeoJSON from $endpoint: ${response.statusCode}");
        }
      } catch (e) {
        print("Error loading GeoJSON from $endpoint: $e");
      }
    }
    _computeHallwayIntersections();
  }

  void _computeHallwayIntersections() {
    for (int i = 0; i < hallways.length; i++) {
      for (int j = i + 1; j < hallways.length; j++) {
        var hallway1 = hallways[i];
        var hallway2 = hallways[j];
        for (int k = 0; k < hallway1.length - 1; k++) {
          for (int l = 0; l < hallway2.length - 1; l++) {
            LatLng? intersection = _findIntersection(
              hallway1[k], hallway1[k + 1],
              hallway2[l], hallway2[l + 1],
            );
            if (intersection != null && !waypoints.contains(intersection)) {
              waypoints.add(intersection);
              print("Added intersection waypoint: $intersection");
            }
          }
        }
      }
    }
  }

  LatLng? _findIntersection(LatLng p1, LatLng q1, LatLng p2, LatLng q2) {
    double x1 = p1.latitude, y1 = p1.longitude;
    double x2 = q1.latitude, y2 = q1.longitude;
    double x3 = p2.latitude, y3 = p2.longitude;
    double x4 = q2.latitude, y4 = q2.longitude;

    double denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if (denom == 0) return null;

    double t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom;
    double u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom;

    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      double x = x1 + t * (x2 - x1);
      double y = y1 + t * (y2 - y1);
      return LatLng(x, y);
    }
    return null;
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
          await http.get(Uri.parse("https://trannguyenanhminh.click/geojson/Paths"));
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
          await http.get(Uri.parse("https://trannguyenanhminh.click/geojson/POI"));
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
            "rp": properties['RP'] ?? 'Unknown',
            "coordinates": LatLng(coordinates[1], coordinates[0]),
            "description": properties['Description'] ?? 'Không có mô tả',
            "images": images,
          });
        }

        for (int i = 0; i < waypoints.length; i++) {
          poiList.add({
            "name": "Waypoint $i",
            "rp": "wp_$i",
            "coordinates": waypoints[i],
            "description": "Điểm trung gian",
            "images": <String>[],
          });
        }

        poiList.add({
          "name": "User Position",
          "rp": userPositionRP,
          "coordinates": userPositionCoordinates,
          "description": "Vị trí hiện tại của bạn",
          "images": <String>[],
        });

        graph = _generateGraph();
        print("Graph generated: $graph");
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
    }

    for (var wp1 in poiList.where((poi) => poi["rp"].startsWith("wp_"))) {
      String wp1RP = wp1["rp"];
      LatLng wp1Coords = wp1["coordinates"];

      for (var wp2 in poiList.where((poi) => poi["rp"].startsWith("wp_"))) {
        if (wp1 == wp2) continue;
        String wp2RP = wp2["rp"];
        LatLng wp2Coords = wp2["coordinates"];

        if (!_isPathBlocked(wp1Coords, wp2Coords)) {
          double distance = _calculateDistance(wp1Coords, wp2Coords);
          generatedGraph[wp1RP]!.add({"rp": wp2RP, "distance": distance});
          print("Added edge between waypoints: $wp1RP -> $wp2RP, distance: $distance");
        }
      }
    }

    for (var poi in poiList) {
      String poiRP = poi["rp"];
      LatLng poiCoords = poi["coordinates"];

      List<Map<String, dynamic>> nearestWaypoints = [];
      for (var wp in poiList.where((p) => p["rp"].startsWith("wp_"))) {
        LatLng wpCoords = wp["coordinates"];
        if (!_isPathBlocked(poiCoords, wpCoords)) {
          double distance = _calculateDistance(poiCoords, wpCoords);
          nearestWaypoints.add({
            "rp": wp["rp"],
            "coordinates": wpCoords,
            "distance": distance,
          });
        }
      }

      nearestWaypoints.sort((a, b) => a["distance"].compareTo(b["distance"]));
      var closestWaypoints = nearestWaypoints.take(3).toList();

      for (var wp in closestWaypoints) {
        String wpRP = wp["rp"];
        double distance = wp["distance"];
        generatedGraph[poiRP]!.add({"rp": wpRP, "distance": distance});
        generatedGraph[wpRP]!.add({"rp": poiRP, "distance": distance});
        print("Added edge: $poiRP -> $wpRP, distance: $distance");
      }

      if (closestWaypoints.isEmpty) {
        for (var otherPoi in poiList) {
          if (otherPoi == poi) continue;
          String otherRP = otherPoi["rp"];
          LatLng otherCoords = otherPoi["coordinates"];
          if (!_isPathBlocked(poiCoords, otherCoords)) {
            double distance = _calculateDistance(poiCoords, otherCoords);
            generatedGraph[poiRP]!.add({"rp": otherRP, "distance": distance});
            print("Added direct edge: $poiRP -> $otherRP, distance: $distance");
          }
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
      print("Start or end POI not found in the graph: start=$start, end=$end");
      return [];
    }

    final Map<String, double> gScore = {for (var node in graph.keys) node: double.infinity};
    final Map<String, double> fScore = {for (var node in graph.keys) node: double.infinity};
    final Map<String, String?> cameFrom = {for (var node in graph.keys) node: null};
    final List<String> openSet = [start];
    final Set<String> closedSet = {};

    gScore[start] = 0;
    fScore[start] = _heuristic(start, end);

    while (openSet.isNotEmpty) {
      openSet.sort((a, b) => fScore[a]!.compareTo(fScore[b]!));
      final current = openSet.removeAt(0);

      if (current == end) {
        final path = <String>[];
        String? temp = current;
        while (temp != null) {
          path.insert(0, temp);
          temp = cameFrom[temp];
        }
        final route = path.map((rp) {
          return poiList.firstWhere((poi) => poi['rp'] == rp)['coordinates'] as LatLng;
        }).toList();
        print("Shortest path found: $path");
        print("Route coordinates: $route");
        return route;
      }

      closedSet.add(current);

      for (var neighbor in graph[current]!) {
        final neighborRP = neighbor['rp'];
        if (closedSet.contains(neighborRP)) continue;

        final tentativeGScore = gScore[current]! + neighbor['distance'];

        if (!openSet.contains(neighborRP)) {
          openSet.add(neighborRP);
        } else if (tentativeGScore >= gScore[neighborRP]!) {
          continue;
        }

        cameFrom[neighborRP] = current;
        gScore[neighborRP] = tentativeGScore;
        fScore[neighborRP] = gScore[neighborRP]! + _heuristic(neighborRP, end);
      }
    }

    print("No path found from $start to $end");
    return [];
  }

  double _heuristic(String current, String goal) {
    final currentPoi = poiList.firstWhere((poi) => poi['rp'] == current);
    final goalPoi = poiList.firstWhere((poi) => poi['rp'] == goal);
    final currentCoords = currentPoi['coordinates'] as LatLng;
    final goalCoords = goalPoi['coordinates'] as LatLng;
    return _calculateDistance(currentCoords, goalCoords);
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

  List<LatLng> _smoothRoute(List<LatLng> route, {int segmentsPerPoint = 10}) {
    if (route.length < 2) return route;

    List<LatLng> smoothedRoute = [];

    LatLng p0 = route.first;
    LatLng p1 = route.first;
    LatLng p2 = route[1];
    LatLng p3 = route.length > 2 ? route[2] : route[1];

    smoothedRoute.add(route.first);

    for (int i = 0; i < route.length - 1; i++) {
      p0 = i > 0 ? route[i - 1] : route.first;
      p1 = route[i];
      p2 = route[i + 1];
      p3 = i + 2 < route.length ? route[i + 2] : route[i + 1];

      for (int j = 1; j <= segmentsPerPoint; j++) {
        double t = j / segmentsPerPoint;
        double t2 = t * t;
        double t3 = t2 * t;

        double x = 0.5 * (
              (2 * p1.latitude) +
              (-p0.latitude + p2.latitude) * t +
              (2 * p0.latitude - 5 * p1.latitude + 4 * p2.latitude - p3.latitude) * t2 +
              (-p0.latitude + 3 * p1.latitude - 3 * p2.latitude + p3.latitude) * t3
          );

        double y = 0.5 * (
              (2 * p1.longitude) +
              (-p0.longitude + p2.longitude) * t +
              (2 * p0.longitude - 5 * p1.longitude + 4 * p2.longitude - p3.longitude) * t2 +
              (-p0.longitude + 3 * p1.longitude - 3 * p2.longitude + p3.longitude) * t3
          );

        smoothedRoute.add(LatLng(x, y));
      }
    }

    smoothedRoute.add(route.last);
    return smoothedRoute;
  }

  List<Marker> _createDottedRoute(List<LatLng> route, {double dotSpacing = 5.0, double dotSize = 10.0}) {
    List<Marker> dottedMarkers = [];

    if (route.length < 2) return dottedMarkers;

    for (int i = 0; i < route.length - 1; i++) {
      LatLng start = route[i];
      LatLng end = route[i + 1];
      double distance = _calculateDistance(start, end);

      int numDots = (distance / dotSpacing).floor();
      if (numDots == 0) numDots = 1;

      for (int j = 0; j <= numDots; j++) {
        double t = j / numDots;
        double lat = start.latitude + (end.latitude - start.latitude) * t;
        double lng = start.longitude + (end.longitude - start.longitude) * t;

        double opacity = (1.0 - (j / numDots)) * 0.6;
        dottedMarkers.add(
          Marker(
            point: LatLng(lat, lng),
            width: dotSize,
            height: dotSize,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(opacity),
                border: Border.all(
                  color: Colors.red.withOpacity(opacity * 0.5),
                  width: 1.0,
                ),
              ),
            ),
          ),
        );
      }
    }

    return dottedMarkers;
  }

  void _drawRouteCD(BuildContext context, VoidCallback setStateCallback, {required bool showDirections}) {
    if (startPOI != null && endPOI != null) {
      originalRoute = _findShortestPath(startPOI!, endPOI!);
      if (originalRoute.isNotEmpty) {
        selectedRoute = _smoothRoute(originalRoute, segmentsPerPoint: 10);
        pathDistance = _calculatePathDistance(originalRoute); // Tính khoảng cách trên đường gốc
        _calculateDirections();
        if (showDirections) {
          _showDirections(context);
          _speakDirections();
        }
        setStateCallback();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy đường đi giữa hai điểm")),
        );
      }
    }
  }

  void _drawRoute(BuildContext context, VoidCallback setStateCallback, {required bool showDirections}) {
    if (startPOI != null && endPOI != null) {
      originalRoute = _findShortestPath(startPOI!, endPOI!);
      if (originalRoute.isNotEmpty) {
        selectedRoute = _smoothRoute(originalRoute, segmentsPerPoint: 10);
        pathDistance = _calculatePathDistance(originalRoute); // Tính khoảng cách trên đường gốc
        _calculateDirections();
        if (showDirections) {
          _showDirections(context);
        }
        setStateCallback();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy đường đi giữa hai điểm")),
        );
      }
    }
  }

  void _onPOITap(String rp, BuildContext context, VoidCallback setStateCallback) {
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
                      startPOI = userPositionRP;
                      endPOI = rp;
                      selectedMarkerRP = userPositionRP;
                      secondSelectedMarkerRP = rp;

                      _drawRouteCD(context, setStateCallback, showDirections: true);
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
                      endPOI = rp;
                      selectedMarkerRP = userPositionRP;
                      secondSelectedMarkerRP = rp;
                      _drawRoute(context, setStateCallback, showDirections: true);
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
    List<Marker> dottedRouteMarkers = selectedRoute.isNotEmpty
        ? _createDottedRoute(selectedRoute, dotSpacing: 5.0, dotSize: 10.0)
        : [];

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            center: userPositionCoordinates,
            zoom: currentZoom,
            minZoom: 15.0,
            maxZoom: 22.0,
            interactiveFlags: InteractiveFlag.all,
            onPositionChanged: (position, hasGesture) {
              if (position.zoom != null) {
                currentZoom = position.zoom!;
                setStateCallback();
              }

              if (position.center != null && !hasGesture) {
                userPositionCoordinates = position.center!;
                final userPoiIndex = poiList.indexWhere((poi) => poi['rp'] == userPositionRP);
                if (userPoiIndex != -1) {
                  poiList[userPoiIndex]['coordinates'] = userPositionCoordinates;
                  graph = _generateGraph();
                }
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
            MarkerLayer(
              rotate: true,
              markers: [
                if (currentZoom >= 20) ...poiList.map((poi) {
                  if (poi['rp'] == userPositionRP) return null;
                  if (poi['name'] == 'Cầu thang') return null;

                  final isSelected = poi['rp'] == selectedMarkerRP || poi['rp'] == secondSelectedMarkerRP;
                  return Marker(
                    point: poi['coordinates'] as LatLng,
                    width: isSelected ? 80.0 : 60.0,
                    height: isSelected ? 80.0 : 60.0,
                    child: GestureDetector(
                      onTap: () {
                        _onPOITap(poi['rp'] as String, context, setStateCallback);
                        setStateCallback();
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.green.withOpacity(0.7) : Colors.white.withOpacity(0.7),
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
                          if (isSelected)
                            Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 30,
                            )
                          else
                            Container(
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
                }).whereType<Marker>().toList(),

                Marker(
                  point: userPositionCoordinates,
                  width: selectedMarkerRP == userPositionRP ? 80.0 : 60.0,
                  height: selectedMarkerRP == userPositionRP ? 80.0 : 60.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: selectedMarkerRP == userPositionRP ? Colors.green.withOpacity(0.7) : Colors.white,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          "User",
                          style: TextStyle(
                            fontSize: selectedMarkerRP == userPositionRP ? 12 : 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.person_pin_circle,
                        color: selectedMarkerRP == userPositionRP ? Colors.red : Colors.blue,
                        size: 32,
                      ),
                    ],
                  ),
                ),

                ...dottedRouteMarkers,
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