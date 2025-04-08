import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class POISelectionScreen {
  final MapController mapController = MapController();
  double currentZoom = 20.0;
  String? startPOI;
  String? endPOI;

  List<Map<String, dynamic>> poiList = [];
  List<LatLng> selectedRoute = [];
  late Map<String, List<Map<String, dynamic>>> graph;
  List<List<LatLng>> walls = [];
  final GeoJsonParser geoJsonParser = GeoJsonParser();
    List<String> directions = [];
     final FlutterTts flutterTts = FlutterTts();

  String? selectedMarkerRP;
  bool _isDataLoaded = false;
  POISelectionScreen() {
    _loadWallsFromAPI(); // Load walls from the Paths API
    _loadPOIData().then((_) {
      _isDataLoaded = true; // Đánh dấu dữ liệu đã tải xong
    });
    loadGeoJson().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnPOIs());
    });
     initTts();
  }
   Future<void> initTts() async {
    try {
      await flutterTts.setLanguage("vi-VN");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      List<dynamic> voices = await flutterTts.getVoices;
      String? vietnameseVoice;

      for (var voice in voices) {
        if (voice['locale'] == 'vi-VN') {
          vietnameseVoice = voice['name'];
          break;
        }
      }

      if (vietnameseVoice != null) {
        await flutterTts.setVoice({"name": vietnameseVoice, "locale": "vi-VN"});
        print("Đã chọn giọng tiếng Việt: $vietnameseVoice");
      } else {
        print("Không tìm thấy giọng tiếng Việt (vi-VN) trên thiết bị.");
      }

      flutterTts.setCompletionHandler(() {
        print("Đã đọc xong một hướng dẫn.");
      });

      flutterTts.setErrorHandler((msg) {
        print("Lỗi Text-to-Speech: $msg");
      });
    } catch (e) {
      print("Lỗi khởi tạo Text-to-Speech: $e");
    }
  }

  Future<void> speakDirections() async {
    if (directions.isEmpty) {
      print("Không có hướng dẫn để đọc.");
      return;
    }

    for (int i = 0; i < directions.length; i++) {
      String direction = "${i + 1}. ${directions[i]}";
      print("Đang đọc: $direction");
      await flutterTts.speak(direction);
      await flutterTts.awaitSpeakCompletion(true);
    }
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
            await http.get(Uri.parse("http://192.168.1.6:8765$endpoint"));
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
                } else if (endpoint == "/geojson/Hallways") {
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
          options: const FitBoundsOptions(padding: EdgeInsets.all(50)));
    }
  }

  Future<void> _loadWallsFromAPI() async {
    try {
      final response =
          await http.get(Uri.parse("http://192.168.1.6:8765/geojson/Paths"));
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
          await http.get(Uri.parse("http://192.168.1.6:8765/geojson/POI"));
      if (response.statusCode == 200) {
        final poiJson = json.decode(response.body);

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
      print("Không tìm thấy điểm đầu hoặc điểm cuối trong đồ thị: start=$start, end=$end");
      return [];
    }

    final Map<String, double> gScores = {};
    final Map<String, double> fScores = {};
    // final Map<String, double> distances = {};
    final Map<String, String?> previous = {};
      final List<String> openSet = [];
    final Set<String> closedSet = {};
    // final List<String> unvisited = [];

    for (var node in graph.keys) {
      gScores[node] = double.infinity;
      fScores[node] = double.infinity;
      // distances[node] = double.infinity;
      previous[node] = null;
      // unvisited.add(node);
    }
    gScores[start] = 0;
    fScores[start] = heuristic(start, end);
    openSet.add(start);

    // distances[start] = 0;

    // while (unvisited.isNotEmpty) {
    //   unvisited.sort((a, b) => distances[a]!.compareTo(distances[b]!));
    //   final current = unvisited.removeAt(0);
    while (openSet.isNotEmpty) {
      openSet.sort((a, b) => fScores[a]!.compareTo(fScores[b]!));
      final current = openSet.removeAt(0);

      if (current == end) break;

      closedSet.add(current);

      for (var neighbor in graph[current]!) {
        // final newDist = distances[current]! + neighbor['distance'];
        // if (newDist < distances[neighbor['rp']]!) {
        //   distances[neighbor['rp']] = newDist;
        //   previous[neighbor['rp']] = current;
         final neighborRP = neighbor['rp'];
        if (closedSet.contains(neighborRP)) continue;

        final tentativeGScore = gScores[current]! + neighbor['distance'];

        if (!openSet.contains(neighborRP)) {
          openSet.add(neighborRP);
        } else if (tentativeGScore >= gScores[neighborRP]!) {
          continue;
        }

        previous[neighborRP] = current;
        gScores[neighborRP] = tentativeGScore;
        fScores[neighborRP] = gScores[neighborRP]! + heuristic(neighborRP, end);
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

  double heuristic(String start, String end) {
    final startPoi = poiList.firstWhere((poi) => poi['rp'] == start);
    final endPoi = poiList.firstWhere((poi) => poi['rp'] == end);
    return _calculateDistance(startPoi['coordinates'], endPoi['coordinates']);
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371;
    double dLat = (point2.latitude - point1.latitude) * (pi / 180);
    double dLon = (point2.longitude - point1.longitude) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(point1.latitude * (pi / 180)) * cos(point2.latitude * (pi / 180)) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c * 1000;
  }

  void _calculateDirections() {
    directions.clear();
    if (selectedRoute.length < 2) return;

    for (int i = 0; i < selectedRoute.length - 1; i++) {
      if (i == 0 || selectedRoute.length < 3) {
        directions.add("Đi thẳng đến đích");
      } else {
        String direction = getDirection(selectedRoute[i - 1], selectedRoute[i], selectedRoute[i + 1]);
        directions.add(direction);
      }
    }

    if (directions.isNotEmpty && directions.last != "Đi thẳng đến đích") {
      directions.add("Đi thẳng đến đích");
    }
  }

  String getDirection(LatLng p1, LatLng p2, LatLng p3) {
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
      return "Rẽ phải";
    } else {
      return "Rẽ trái";
    }
  }

  void _showDirections(BuildContext context) {
    if (directions.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hướng dẫn đường đi'),
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
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void drawRoute(BuildContext context, VoidCallback setStateCallback, {bool withSpeech = false}) {
    if (startPOI != null && endPOI != null) {
      selectedRoute = _findShortestPath(startPOI!, endPOI!);
      if (selectedRoute.isNotEmpty) {
        _calculateDirections();
        _showDirections(context);
        if (withSpeech) {
          speakDirections();
        }
        setStateCallback();
      }
    }
  }

  void _onPOITap(String rp, BuildContext context, VoidCallback setStateCallback) {
    if (!_isDataLoaded) {
      print("Dữ liệu POI chưa được tải xong.");
      return;
    }

    selectedMarkerRP = rp;
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

    showPOIDetailsDialog(
      context: context,
      name: poi['name'],
      description: poi['description'] ?? 'Không có mô tả',
      images: poi['images'] ?? <String>[],
      setStateCallback: setStateCallback,
      onFindRoute: () {
    if (startPOI == null) {
          startPOI = rp;
        } else if (endPOI == null && startPOI != rp) {
      endPOI = rp;
          drawRoute(context, setStateCallback, withSpeech: false);
        } else if (startPOI == rp) {
          startPOI = null;
          endPOI = null;
          selectedRoute = [];
          directions.clear();
    } else {
          startPOI = rp;
          endPOI = null;
          selectedRoute = [];
          directions.clear();
        }
        setStateCallback();
      },
      onSetStart: () {
        startPOI = rp;
        if (endPOI != null && startPOI != endPOI) {
          drawRoute(context, setStateCallback, withSpeech: true);
        }
        setStateCallback();
      },
    );
    setStateCallback();
  }

  void showPOIDetailsDialog({
    required BuildContext context,
    required String name,
    required String description,
    required List<String> images,
    required VoidCallback setStateCallback,
    required VoidCallback onFindRoute,
    required VoidCallback onSetStart,
  }) {
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
                    name,
                    style: GoogleFonts.openSans(
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
                description,
                style: GoogleFonts.openSans(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: onSetStart,
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: Text(
                      "Bắt đầu",
                      style: GoogleFonts.openSans(color: Colors.white),
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
                    onPressed: onFindRoute,
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: Text(
                      startPOI == null ? "Chọn điểm" : "Tìm đường",
                      style: GoogleFonts.openSans(color: Colors.white),
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
                child: images.isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                images[index],
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
  }

  Widget buildMapSection(BuildContext context, VoidCallback setStateCallback) {
    return FutureBuilder(
      future: _loadPOIData(), // Đảm bảo dữ liệu được tải trước khi xây dựng bản đồ
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Lỗi khi tải dữ liệu POI"));
        }

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
              subdomains: const ['a', 'b', 'c'],
        ),
        if (geoJsonParser.polygons.isNotEmpty)
          PolygonLayer(polygons: geoJsonParser.polygons),
        if (geoJsonParser.polylines.isNotEmpty)
          PolylineLayer(polylines: geoJsonParser.polylines),
            if (geoJsonParser.markers.isNotEmpty)
        MarkerLayer(
                markers: geoJsonParser.markers.map((marker) {
                  final showName = currentZoom >= 20;
                  final poi = poiList.firstWhere(
                      (poi) => poi['coordinates'] == marker.point,
                      orElse: () => {"rp": ""});
                  final isSelected =
                      (poi['rp'] == startPOI || poi['rp'] == endPOI);
              return Marker(
                point: poi['coordinates'] as LatLng,
                width: 80.0,
                height: 80.0,
                child: GestureDetector(
                  onTap: () {
                        if (poi['rp'] != "") {
                          _onPOITap(poi['rp'] as String, context, setStateCallback);
                        }
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
                          poi['name'] ?? "Unknown", // Display Name
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.location_on,
                            color: isSelected ? Colors.green : Colors.red,
                            size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            ),
          
          //             ),
          //           ),
          //         ),
          //         Icon(
          //           Icons.person_pin_circle,
          //           color: Colors.blue, // User position marker color
          //           size: 30,
          //         ),
          //       ],
          //     ),
          //   ),
          // ],
        
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
      },
    );
  }
}