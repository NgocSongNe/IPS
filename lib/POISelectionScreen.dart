import 'package:flutter/material.dart';
import 'package:flutter_application_1/information.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

import 'dart:ui' as ui;
import 'package:flutter_application_1/services/tts_service.dart';
import 'package:flutter_application_1/services/compass_service.dart';
import 'package:flutter_application_1/services/route_service.dart'; 
import 'package:flutter_application_1/services/geometry_services.dart'; // Import GeometryService
class POISelectionScreen {
  final MapController mapController = MapController();
  double currentZoom = 20.0;
  String? startPOI;
  String? endPOI;
  LatLng userPositionCoordinates;
  double? pathDistance;
  List<Map<String, dynamic>> poiList = [];
  List<LatLng> selectedRoute = [];
  List<LatLng> originalRoute = [];
  late Map<String, List<Map<String, dynamic>>> graph;
  List<List<LatLng>> walls = [];
  List<List<LatLng>> hallways = [];
  List<LatLng> waypoints = [];
  final GeoJsonParser geoJsonParser = GeoJsonParser();
  late LatLngBounds mapBounds; 
 
  String userPositionRP = "userPosition";
  List<String> directions = [];
  List<double> segmentDistances = [];

  String? selectedMarkerRP;
  String? secondSelectedMarkerRP;

  final BuildContext context;

   double _compassHeading = 0.0;
  final Function startWifiTracking;
  final Function stopWifiTracking;

   String? selectedCategory;

  
  int mockPositionIndex = 0;
  List<LatLng> mockUserPositions = [];

final TTSService ttsService = TTSService(); 
final RouteService routeService = RouteService();  
  final GeometryService geometryService = GeometryService(); 


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
String _getCategoryFromRP(String rp) {
  String folderName = rpToFolderMap[rp] ?? 'unknown';

  // Định nghĩa các category theo folderName
  Map<String, String> categoryMap = {
    'tv3_4': 'TV3,4',
    'hoi_truong_thu_vien': 'Hội trường thư viện',
    'khu_vuc_doc': 'Khu vực đọc',
    'can_tin': 'Căn tin',
    'phong_tap_chi': 'Phòng tạp chí',
    'ban_thu_thu': 'Kệ sách',
    'khu_vuc_tu_hoc': 'Khu vực tự học',
    'hanh_lang': 'Hành lang',
    'cua_ra_vao': 'Cửa ra vào',
    'cau_thang': 'Cầu thang',
    'cau_thang_tang_2': 'Cầu thang tầng 2',
  };

  // Trả về category dựa trên folderName
  return categoryMap[folderName] ?? 'Khác'; // Trả về 'Khác' nếu không có tên category
}

  POISelectionScreen(
    {required this.userPositionCoordinates,  required this.selectedCategory,required this.context,required this.startWifiTracking, required this.stopWifiTracking}) {
    _loadWallsFromAPI();
    loadPOIData();
    loadGeoJson().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusOnPOIs();
        _initializeMockUserPositions(); // Khởi tạo mockUserPositions sau khi có waypoints
      });
    });
    ttsService.initTts();
    _initCompass(); // Khởi tạo cảm biến la bàn

  }


void setMapPosition(LatLng position, double zoom) {
  userPositionCoordinates = position;
  currentZoom = zoom;
  mapController.move(position, zoom);  // Cập nhật vị trí và mức zoom của bản đồ
}
  void _initCompass() {
    CompassService().initCompass((heading) {
      _compassHeading = heading;
    });
  }

void _initTts() {
    ttsService.initTts();  // Gọi hàm khởi tạo TTS từ TTSService
  }

  // Hàm phát âm hướng dẫn từ TTSService
  void _speakDirections() {
     print("Starting to speak directions...");
    ttsService.speakDirections(directions, segmentDistances);  // Gọi hàm phát âm từ TTSService
  }
  void _computeHallwayIntersections() {
    geometryService.computeHallwayIntersections(hallways, waypoints);
  }
void _calculateDirections() {
  directions.clear();
  segmentDistances.clear();
  if (originalRoute.length < 2) {
    print("Original route has less than 2 points, cannot calculate directions.");
    return;
  }

  for (int i = 0; i < originalRoute.length - 1; i++) {
    double segmentDistance = routeService.calculateDistance(originalRoute[i], originalRoute[i + 1]);
    segmentDistances.add(segmentDistance);

    if (i == 0 || originalRoute.length < 3) {
      directions.add("Đi thẳng đến đích");
    } else {
      String direction = routeService.getDirection(
          originalRoute[i - 1], originalRoute[i], originalRoute[i + 1]);
      directions.add(direction);
    }
  }

  if (directions.isNotEmpty && directions.last != "Đi thẳng đến đích") {
    directions.add("Đi thẳng đến đích");
    if (originalRoute.length > 1) {
      segmentDistances.add(routeService.calculateDistance(
          originalRoute[originalRoute.length - 2], originalRoute.last));
    }
  }
  print("Directions: $directions");
  print("Segment Distances: $segmentDistances");
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

  // Hàm mới để lưu trữ thông tin mô tả của các POI
  Map<String, String> getPOIDescriptions() {
    return {
      "1": "Phòng máy tính TV3 và TV4.",
      "2": "Cửa ra vào thư viện",
      "3": "Phòng Hội trường thư viện, không gian rộng lớn, hiện đại.",
      "4": "Cầu thang di chuyển.",
      "5": "Cầu thang di chuyển.",
      "6": "Cầu thang di chuyển.",
      "7": "Cầu thang di chuyển.",
      "8": "Khu vực có đầy đủ bàn ghế, ổ cắm điện, không gian yên tĩnh.",
      "9": "Căn tin hiện đại, cung cấp nhiều loại mặt hàng.",
      "10": "Cầu thang di chuyển.",
      "11": "Cầu thang di chuyển.",
      "12": "Khu vực có đầy đủ bàn ghế, ổ cắm điện, không gian yên tĩnh.",
      "13": "Khu vực có đầy đủ bàn ghế, ổ cắm điện, không gian yên tĩnh.",
      "14": "Khu vực có đầy đủ bàn ghế, ổ cắm điện, không gian yên tĩnh.",
      "15": "Khu vực có đầy đủ bàn ghế, ổ cắm điện, không gian yên tĩnh.",
      // "16": "Hành lang di chuyển giữa các khu vực.",
      // "17": "Hành lang di chuyển giữa các khu vực.",
      "18": "Khu vực có đầy đủ bàn ghế, ổ cắm điện, không gian yên tĩnh.",
      "19": "Cầu thang di chuyển.",
      "20": "Cầu thang di chuyển.",
      "21": "Cầu thang di chuyển.",
      "22": "Khu vực cung cấp các thể loại sách, môi trường yên tĩnh.",
      "23": "Khu vực có đầy đủ bàn ghế, ổ cắm điện, không gian yên tĩnh.",
      "24": "Khu vực có đầy đủ bàn ghế, ổ cắm điện, không gian yên tĩnh.",
      "25": "Khu vực cung cấp các thể loại sách, môi trường yên tĩnh.",
      "26": "Khu vực cung cấp các thể loại sách, môi trường yên tĩnh.",
      "27": "Khu vực cung cấp các thể loại sách, môi trường yên tĩnh.",
      "28": "Cầu thang di chuyển.",
      "29": "Cầu thang di chuyển.",
      "30": "Khu vực cung cấp các thể loại sách, môi trường yên tĩnh.",
      "31": "Khu vực cung cấp các thể loại sách, môi trường yên tĩnh.",
      "32": "Cầu thang di chuyển.",
      "33": "Cầu thang dẫn lên tầng 2",
      "34": "Cửa ra vào thư viện",
      "35": "Khu vực có đầy đủ bàn ghế, ổ cắm điện, không gian yên tĩnh.",
      "36": "Khu vực làm việc trung tâm của thủ thư.",
      "37": "Khu vực làm việc trung tâm của thủ thư.",
      "38": "Khu vực có đầy đủ bàn ghế, ổ cắm điện, không gian yên tĩnh.",
      "39": "Phòng lưu trữ tạp chí và nhiều sách đa dạng thể loại.",
      "40": "Cầu thang dẫn lên tầng 2",
    };
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
            await http.get(Uri.parse("http://192.168.1.11:8765$endpoint"));
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
                          textAlign: TextAlign.center,
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
                  fillColor = Colors.blue.withOpacity(0.5);
                } else if (endpoint == "/geojson/Wall") {
                  fillColor = Colors.grey.withOpacity(0.3);
                  walls.add(points);
                } else if (endpoint == "/geojson/Hallways") {
                  fillColor = Colors.grey.withValues(alpha: 0.5);
                  hallways.add(points);
                  waypoints.addAll(points);
                } else {
                  fillColor = Colors.transparent;
                }

                geoJsonParser.polygons.add(
                  Polygon(
                    points: points,
                    isFilled: true,
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

  void _focusOnPOIs() {
    if (geoJsonParser.markers.isNotEmpty) {
      final latitudes =
          geoJsonParser.markers.map((m) => m.point.latitude).toList();
      final longitudes =
          geoJsonParser.markers.map((m) => m.point.longitude).toList();

      mapBounds = LatLngBounds(
        LatLng(latitudes.reduce((a, b) => a < b ? a : b),
            longitudes.reduce((a, b) => a < b ? a : b)),
        LatLng(latitudes.reduce((a, b) => a > b ? a : b),
            longitudes.reduce((a, b) => a > b ? a : b)),
      );

      mapController.fitBounds(
        mapBounds,
        options: FitBoundsOptions(padding: EdgeInsets.all(50)),
      );

      print("Map bounds: Southwest (${mapBounds.south}, ${mapBounds.west}), Northeast (${mapBounds.north}, ${mapBounds.east})");
    }
  }

  void _initializeMockUserPositions() {
    // Lấy tọa độ từ waypoints để đảm bảo tất cả đều nằm trong bản đồ
    if (waypoints.isNotEmpty) {
      // Lấy tối đa 5 điểm từ waypoints để làm tọa độ mô phỏng
      mockUserPositions = waypoints.take(5).toList();
      if (mockUserPositions.isEmpty) {
        // Nếu không có waypoints, lấy tọa độ từ poiList (trừ vị trí User)
        mockUserPositions = poiList
            .where((poi) => poi['rp'] != userPositionRP)
            .map((poi) => poi['coordinates'] as LatLng)
            .take(5)
            .toList();
      }
      print("Initialized mockUserPositions: $mockUserPositions");
    } else {
      print("No waypoints available, mockUserPositions not initialized.");
    }
  }

  Future<void> _loadWallsFromAPI() async {
    try {
      final response =
          await http.get(Uri.parse("http://192.168.1.11:8765/geojson/Paths"));
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

  Future<void> loadPOIData() async {
    try {
      final response =
          await http.get(Uri.parse("http://192.168.1.11:8765/geojson/POI"));
      if (response.statusCode == 200) {
        final poiJson = jsonDecode(response.body);
        // Lấy dữ liệu mô tả từ hàm getPOIDescriptions
        final poiDescriptions = getPOIDescriptions();

        poiList = [];
        for (var feature in poiJson['features']) {
          final properties = feature['properties'];
          final coordinates = feature['geometry']['coordinates'];
          
          String category = properties['Name'] ?? 'Unknown';
          String rp = properties['RP'] ?? 'unknown';
          String folderName = rpToFolderMap[rp] ?? 'unknown';
          List<String> images = await _getImagesFromFolder(folderName);

             if (selectedCategory == null || selectedCategory == category) {
          var poi = {
            "name": properties['Name'] ?? 'Unknown',
            "rp": properties['RP'] ?? 'Unknown',
            "coordinates": LatLng(coordinates[1], coordinates[0]),
            // Sử dụng mô tả từ getPOIDescriptions thay vì từ file geojson
            "description": poiDescriptions[rp] ?? 'Không có mô tả',
            "images": images,
            "category": category,
          };

          print(
              "Loaded POI: ${poi['name']}, RP: ${poi['rp']}, Description: ${poi['description']}");

          poiList.add(poi);
        }
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
// Hàm tạo route dọc theo các điểm, sử dụng cho việc vẽ các điểm trong khoảng cách
  List<Marker> createDottedRoute(List<LatLng> route, {double dotSpacing = 5.0, double dotSize = 10.0}) {
    List<Marker> dottedMarkers = [];

    if (route.length < 2) return dottedMarkers;

    for (int i = 0; i < route.length - 1; i++) {
      LatLng start = route[i];
      LatLng end = route[i + 1];
      double distance = routeService.calculateDistance(start, end);

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
                color: Colors.blue
                    .withOpacity(opacity), // Đổi màu thành xanh dương
                border: Border.all(
                  color: Colors.blue.withOpacity(
                      opacity * 0.5), // Đổi màu viền thành xanh dương
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
  Map<String, List<Map<String, dynamic>>> _generateGraph() {
    Map<String, List<Map<String, dynamic>>> generatedGraph = {};

    for (var poi in poiList) {
      String poiRP = poi["rp"];
      generatedGraph[poiRP] = [];
      LatLng coordinates = poi["coordinates"];
    }

    for (var wp1 in poiList.where((poi) => poi["rp"].startsWith("wp_"))) {
      String wp1RP = wp1["rp"];
      LatLng wp1Coords = wp1["coordinates"];

      for (var wp2 in poiList.where((poi) => poi["rp"].startsWith("wp_"))) {
        if (wp1 == wp2) continue;
        String wp2RP = wp2["rp"];
        LatLng wp2Coords = wp2["coordinates"];

        if (!_isPathBlocked(wp1Coords, wp2Coords)) {
          double distance = routeService.calculateDistance(wp1Coords, wp2Coords);
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
          double distance = routeService.calculateDistance(poiCoords, wpCoords);
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
            double distance = routeService.calculateDistance(poiCoords, otherCoords);
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
      print("Start or end POI not found in the graph: start=$start, end=$end");
      return [];
    }

    final Map<String, double> gScore = {for (var node in graph.keys) node: double.infinity};
    final Map<String, double> fScore = {for (var node in graph.keys) node: double.infinity};
    final Map<String, String?> cameFrom = {for (var node in graph.keys) node: null};
    final List<String> openSet = [start];
    final Set<String> closedSet = {};

    gScore[start] = 0;
    fScore[start] = routeService.heuristic(start, end,poiList);

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
        fScore[neighborRP] = gScore[neighborRP]! + routeService.heuristic(neighborRP, end,poiList);
      }
    }

    print("No path found from $start to $end");
    return [];
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

        double x = 0.5 *
            ((2 * p1.latitude) +
              (-p0.latitude + p2.latitude) * t +
                (2 * p0.latitude -
                        5 * p1.latitude +
                        4 * p2.latitude -
                        p3.latitude) *
                    t2 +
                (-p0.latitude +
                        3 * p1.latitude -
                        3 * p2.latitude +
                        p3.latitude) *
                    t3);

        double y = 0.5 *
            ((2 * p1.longitude) +
              (-p0.longitude + p2.longitude) * t +
                (2 * p0.longitude -
                        5 * p1.longitude +
                        4 * p2.longitude -
                        p3.longitude) *
                    t2 +
                (-p0.longitude +
                        3 * p1.longitude -
                        3 * p2.longitude +
                        p3.longitude) *
                    t3);

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
      double distance = routeService.calculateDistance(start, end);

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
                color: Colors.blue
                    .withOpacity(opacity), // Đổi màu thành xanh dương
                border: Border.all(
                  color: Colors.blue.withOpacity(
                      opacity * 0.5), // Đổi màu viền thành xanh dương
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

  void _drawRouteCD(BuildContext context, VoidCallback setStateCallback,
      {required bool showDirections}) {
    if (startPOI != null && endPOI != null) {
      originalRoute = _findShortestPath(startPOI!, endPOI!);
      if (originalRoute.isNotEmpty) {
        selectedRoute = _smoothRoute(originalRoute, segmentsPerPoint: 10);
        pathDistance = routeService.calculatePathDistance(originalRoute);
        _calculateDirections();
        if (showDirections) {
          _showDirections(context);
          _speakDirections();
        }
        setStateCallback();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Không tìm thấy đường đi giữa hai điểm")),
        );
      }
    }
  }

  void _drawRoute(BuildContext context, VoidCallback setStateCallback, {required bool showDirections}) {
    if (startPOI != null && endPOI != null) {
      originalRoute = _findShortestPath(startPOI!, endPOI!);
      if (originalRoute.isNotEmpty) {
        selectedRoute = _smoothRoute(originalRoute, segmentsPerPoint: 10);
        pathDistance = routeService.calculatePathDistance(originalRoute); // Tính khoảng cách trên đường gốc
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


  void onPOITap(String rp, BuildContext context, VoidCallback setStateCallback) {
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

    selectedMarkerRP = rp;  // Đánh dấu POI này là đã chọn

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
                    poi['name'] ?? "Unknown",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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
             SingleChildScrollView(  // Cho phép cuộn ngang
  scrollDirection: Axis.horizontal,  // Cuộn theo chiều ngang
  child: Row(
                children: [
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      startPOI = userPositionRP;
                      endPOI = rp;
                      selectedMarkerRP = userPositionRP;
                      secondSelectedMarkerRP = rp;

                      _drawRouteCD(context, setStateCallback,
                      showDirections: true);
                      Navigator.of(context).pop();
                      startWifiTracking();
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
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Điều hướng đến màn hình InformationPage
                      Navigator.of(context).pop(); // Đóng bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InformationPage(
                            poiName: poi['name'], // Truyền tên địa điểm (poi['name']) vào InformationPage
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info, color: Colors.white),
                    label: const Text(
                      "Thông tin",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700], // Màu vàng
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
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
                                          child: Icon(Icons.error,
                                              color: Colors.white),
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
            zoom: 22.0,
            minZoom: 17.0,
            maxZoom: 23.0,
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

                if (endPOI != null) {
                  startPOI = userPositionRP;
                  _drawRoute(context, setStateCallback, showDirections: false);
                }

                setStateCallback();
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://api.mapbox.com/styles/v1/mapbox/outdoors-v11/tiles/{z}/{x}/{y}?access_token={accessToken}",
              subdomains: ['a', 'b', 'c'],
              additionalOptions: {
                'accessToken': 'pk.eyJ1Ijoic29uZ3RhbmczMDA5IiwiYSI6ImNtODA1NGZkYjA0c2kya29rMWZxYm03MWoifQ.Us8IrAhRJNDO-5qJnfAoIg'
              }
            ),
            if (geoJsonParser.polygons.isNotEmpty)
              PolygonLayer(polygons: geoJsonParser.polygons),
            MarkerLayer(
              rotate: true,
              markers: [
                if (currentZoom >= 20) ...poiList.map((poi) {
                  if (poi['rp'] == userPositionRP) return null;
                  
                  if (poi['name'] == 'Cầu thang') return null;
                  final isHighlighted = selectedCategory != null && _getCategoryFromRP(poi['rp']) == selectedCategory;
                  
                  final isSelected = poi['rp'] == selectedMarkerRP || poi['rp'] == secondSelectedMarkerRP;
                  final poiCategory = _getCategoryFromRP(poi['rp']); // Get category of POI
                  return Marker(
                    point: poi['coordinates'] as LatLng,
                    width: isSelected ? 100.0 :  (isHighlighted ? 90.0 : 90.0),
                    height: isSelected ? 100.0 : (isHighlighted ? 90.0 : 90.0),
                    child: GestureDetector(
                      onTap: () {
                        onPOITap(poi['rp'] as String, context, setStateCallback);
                        setStateCallback();
                      },
                      
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                            decoration: BoxDecoration(
                               color: isSelected
                ? Colors.green.withOpacity(0.7) // Green if selected
                : isHighlighted
                    ? Colors.blue.withOpacity(0.7) // Highlighted category POIs in blue
                    : Colors.white.withOpacity(0.7), 
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              poi['name'] ?? "Unknown",
                              style: TextStyle(
                                fontSize: isSelected ? 12 : 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                               textAlign: TextAlign.center,
                            ),
                           
                          ),
                          if (isSelected)
                            Icon(
                              Icons.location_on,
                               color: isSelected
              ? Colors.green // Green if selected
              : isHighlighted
                  ? Colors.blue // Blue if highlighted by category
                  : Colors.red, 
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
                      })
                      .whereType<Marker>()
                      .toList(),
                // Marker cho vùng hình nón
                Marker(
                  point: userPositionCoordinates,
                  width: 100.0,
                  height: 100.0,
                  child:  Transform.rotate(
                    angle: -_compassHeading * pi / 180, // Xoay theo góc la bàn
                    child: CustomPaint(
                      size: Size(100, 100),
                      painter: ConePainter(),
                    ),
                  ),
                ),
                // Marker cho vị trí User
                Marker(
                  point: userPositionCoordinates,
                  width: selectedMarkerRP == userPositionRP ? 80.0 : 60.0,
                  height: selectedMarkerRP == userPositionRP ? 80.0 : 60.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: selectedMarkerRP == userPositionRP
                              ? Colors.green.withOpacity(0.7)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          "User",
                          style: TextStyle(
                            fontSize: selectedMarkerRP == userPositionRP ? 15 : 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.person_pin_circle,
                        color: selectedMarkerRP == userPositionRP ? Colors.red : Colors.blue,
                        size: 30,
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
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              if (mockUserPositions.isEmpty) {
                print("mockUserPositions is empty, cannot simulate movement.");
                return;
              }

              if (mockPositionIndex < mockUserPositions.length) {
                // Cập nhật vị trí User
                userPositionCoordinates = mockUserPositions[mockPositionIndex];
                mockPositionIndex++;
                if (mockPositionIndex == mockUserPositions.length) {
                  mockPositionIndex = 0; // Quay lại đầu danh sách
                }

                // Cập nhật tọa độ của User trong poiList
                final userPoiIndex = poiList.indexWhere((poi) => poi['rp'] == userPositionRP);
                if (userPoiIndex != -1) {
                  poiList[userPoiIndex]['coordinates'] = userPositionCoordinates;
                  graph = _generateGraph(); // Cập nhật đồ thị
                }

                // Di chuyển bản đồ đến vị trí mới của User
                mapController.move(userPositionCoordinates, currentZoom);

                // Nếu có endPOI, vẽ lại đường đi
                if (endPOI != null) {
                  startPOI = userPositionRP;
                  _drawRoute(context, setStateCallback, showDirections: false);
                }

                // Làm mới giao diện
                setStateCallback();
              }
            },
            child: Icon(Icons.directions_walk),
            tooltip: "Mô phỏng di chuyển",
            ),
          ),
      ],
    );
  }

  // Phương thức public để gọi _drawRoute từ bên ngoài
  void callDrawRoute(BuildContext context, VoidCallback setStateCallback,
      {required bool showDirections}) {
    _drawRoute(context, setStateCallback, showDirections: showDirections);
  }

  // Phương thức public để gọi _drawRouteCD từ bên ngoài
  void callDrawRouteCD(BuildContext context, VoidCallback setStateCallback,
      {required bool showDirections}) {
    _drawRouteCD(context, setStateCallback, showDirections: showDirections);
  }
}

// CustomPainter để vẽ vùng hình nón
class ConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const coneAngle = 60 * pi / 180; // Góc của hình nón (60 độ)

    // Vẽ hình nón
    final path = ui.Path()
      ..moveTo(center.dx, center.dy) // Đỉnh của hình nón
      ..lineTo(
        center.dx + radius * cos(-coneAngle / 2),
        center.dy + radius * sin(-coneAngle / 2),
      )
      ..arcToPoint(
        Offset(
          center.dx + radius * cos(coneAngle / 2),
          center.dy + radius * sin(coneAngle / 2),
        ),
        radius: ui.Radius.circular(radius),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}