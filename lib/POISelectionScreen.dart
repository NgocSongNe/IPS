<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart'; // Thêm import cho GoogleFonts

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

  LatLng userPositionCoordinates = LatLng(11.957103446948263, 108.4451276943349);
  String? selectedMarkerRP;
  String? secondSelectedMarkerRP;

  List<String> directions = [];

  POISelectionScreen() {
    _loadWallsFromAPI();
    _loadPOIData();
    loadGeoJson().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnPOIs());
    });
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
        final response = await http.get(Uri.parse("http://10.0.2.2:5000$endpoint"));
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
          print("Failed to load GeoJSON from $endpoint: ${response.statusCode}");
        }
      } catch (e) {
        print("Error loading GeoJSON from $endpoint: $e");
      }
    }
  }

  void _focusOnPOIs() {
    if (geoJsonParser.markers.isNotEmpty) {
      final latitudes = geoJsonParser.markers.map((m) => m.point.latitude).toList();
      final longitudes = geoJsonParser.markers.map((m) => m.point.longitude).toList();

      final bounds = LatLngBounds(
        LatLng(latitudes.reduce((a, b) => a < b ? a : b), longitudes.reduce((a, b) => a < b ? a : b)),
        LatLng(latitudes.reduce((a, b) => a > b ? a : b), longitudes.reduce((a, b) => a > b ? a : b)),
      );

      mapController.fitBounds(bounds, options: FitBoundsOptions(padding: EdgeInsets.all(50)));
    }
  }

  Future<void> _loadWallsFromAPI() async {
    try {
      final response = await http.get(Uri.parse("http://10.0.2.2:5000/geojson/Paths"));
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
        walls = wallList.map((wall) => wall['coordinates'] as List<LatLng>).toList(); // Fallback to local data
      }
    } catch (e) {
      print("Error loading walls data: $e");
      walls = wallList.map((wall) => wall['coordinates'] as List<LatLng>).toList(); // Fallback to local data
    }
  }

  Future<void> _loadPOIData() async {
    try {
      final response = await http.get(Uri.parse("http://10.0.2.2:5000/geojson/POI"));
      if (response.statusCode == 200) {
        final poiJson = json.decode(response.body);

        poiList = (poiJson['features'] as List).map((feature) {
          final properties = feature['properties'];
          final coordinates = feature['geometry']['coordinates'];
          return {
            "name": properties['Name'] ?? 'Unknown',
            "rp": properties['RP'] ?? 'Unknown',
            "coordinates": LatLng(coordinates[1], coordinates[0]),
            "description": properties['Description'] ?? 'Không có mô tả', // Giả lập nếu API có trường này
            "images": properties['Images'] != null ? List<String>.from(properties['Images']) : <String>[] // Giả lập nếu API có trường này
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
    if (start == "userPosition") {
      double minDistance = double.infinity;
      String? closestPOI;
      LatLng? closestCoordinates;

      for (var poi in poiList) {
        double distance = _calculateDistance(userPositionCoordinates, poi['coordinates']);
        if (distance < minDistance) {
          minDistance = distance;
          closestPOI = poi['rp'];
          closestCoordinates = poi['coordinates'];
        }
      }

      if (closestPOI != null && closestCoordinates != null) {
        return [userPositionCoordinates, ..._findShortestPathFromGraph(closestPOI, end)];
      } else {
        print("No valid POI found near userPositionCoordinates.");
        return [];
      }
    }

    return _findShortestPathFromGraph(start, end);
  }

  List<LatLng> _findShortestPathFromGraph(String start, String end) {
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
        String direction = _getDirection(selectedRoute[i - 1], selectedRoute[i], selectedRoute[i + 1]);
        directions.add(direction);
      }
    }

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

  void _showPOIDetailsDialog({
    required BuildContext context,
    required String name,
    required String description,
    required List<String> images,
    required VoidCallback setStateCallback,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: EdgeInsets.all(16),
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
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                description,
                style: GoogleFonts.openSans(fontSize: 14),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (startPOI != null && endPOI != null) {
                        _drawRoute(context, setStateCallback);
                      }
                    },
                    icon: Icon(Icons.directions, color: Colors.white),
                    label: Text(
                      "Đường đi",
                      style: GoogleFonts.openSans(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      startPOI = "userPosition";
                      endPOI = selectedMarkerRP;
                      _drawRoute(context, setStateCallback);
                    },
                    icon: Icon(Icons.navigation, color: Colors.white),
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
                ],
              ),
              SizedBox(height: 10),
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
                                    child: Center(
                                      child: Icon(Icons.error, color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      )
                    : Center(child: Text("Không có hình ảnh")),
              ),
            ],
          ),
        );
      },
    );
  }

  void _drawRoute(BuildContext context, VoidCallback setStateCallback) {
    if (startPOI != null && endPOI != null) {
      selectedRoute = _findShortestPath(startPOI!, endPOI!);
      if (selectedRoute.isNotEmpty) {
        _calculateDirections();
        _showDirections(context);
        setStateCallback();
      }
    }
  }

  void _onMarkerTap(String rp, BuildContext context, VoidCallback setStateCallback) {
    selectedMarkerRP = rp;
    var poi = poiList.firstWhere((poi) => poi['rp'] == rp);
    _showPOIDetailsDialog(
      context: context,
      name: poi['name'],
      description: poi['description'] ?? 'Không có mô tả',
      images: poi['images'] ?? <String>[],
      setStateCallback: setStateCallback,
    );
    setStateCallback();
  }

  void _onPOITap(String rp, BuildContext context, VoidCallback setStateCallback) {
    if (startPOI == null) {
      startPOI = "userPosition";
      endPOI = rp;
      _drawRoute(context, setStateCallback);
    } else {
      startPOI = null;
      endPOI = null;
      selectedRoute = [];
      directions.clear();
      setStateCallback();
    }
  }

  Widget buildMapSection(BuildContext context, VoidCallback setStateCallback) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: LatLng(11.957103446948263, 108.4451276943349),
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
        if (geoJsonParser.polygons.isNotEmpty) PolygonLayer(polygons: geoJsonParser.polygons),
        if (geoJsonParser.polylines.isNotEmpty) PolylineLayer(polylines: geoJsonParser.polylines),
        MarkerLayer(
          rotate: true,
          markers: [
            ...poiList.map((poi) {
              final isSelected = poi['rp'] == selectedMarkerRP || poi['rp'] == secondSelectedMarkerRP;
              return Marker(
                point: poi['coordinates'] as LatLng,
                width: 80.0,
                height: 80.0,
                child: GestureDetector(
                  onTap: () {
                    _onMarkerTap(poi['rp'] as String, context, setStateCallback);
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
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.location_on,
                        color: isSelected ? Colors.green : Colors.red,
                        size: 30,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            Marker(
              point: userPositionCoordinates,
              width: 80.0,
              height: 80.0,
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
                      "User Position",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 30,
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
    );
  }
=======
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
import 'dart:convert';
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

  POISelectionScreen() {
    _loadWallsFromAPI(); // Load walls from the Paths API
    _loadPOIData();
    loadGeoJson().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnPOIs());
    });
  }
  List<String> directions = [];
  String userPositionRP = "userPosition"; // User's current position RP
  LatLng userPositionCoordinates = LatLng(11.95722012378790, 108.44507513707570); // Coordinates for RP13

  String? selectedMarkerRP; // Track the currently selected marker
  String? secondSelectedMarkerRP; // Track the second selected marker

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
        String direction = _getDirection(
            selectedRoute[i - 1], selectedRoute[i], selectedRoute[i + 1]);
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
                String? category;

                if (endpoint == "/geojson/Room") {
                  fillColor = Colors.blue.withOpacity(0.3);
                  String roomName = properties['Name'] ?? 'Unknown';
                  if (roomName.toLowerCase().contains('phòng vệ sinh') || roomName.toLowerCase().contains('wc')) {
                    category = "Phòng vệ sinh";
                  }
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

                // Add to customPolygons instead of directly to geoJsonParser.polygons
                customPolygons.add(
                  CustomPolygon(
                    polygon: Polygon(
                      points: points,
                      color: fillColor,
                      borderColor: fillColor.withOpacity(0.8),
                      borderStrokeWidth: 2,
                      label: properties['Name'],
                    ),
                    category: category,
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

  void updateMarkersForCategory(String? category, VoidCallback setStateCallback) {
    selectedCategory = category;

    // If category is "Phòng vệ sinh", work with Polygons (Room)
    if (category == "Phòng vệ sinh") {
      // Rebuild the polygons list with updated colors
      List<CustomPolygon> updatedPolygons = [];
      for (var customPolygon in customPolygons) {
        if (customPolygon.category == selectedCategory) {
          // Highlight Polygon with green color
          updatedPolygons.add(CustomPolygon(
            polygon: Polygon(
              points: customPolygon.polygon.points,
              color: Colors.green.withOpacity(0.5),
              borderColor: Colors.green.withOpacity(0.8),
              borderStrokeWidth: customPolygon.polygon.borderStrokeWidth,
              label: customPolygon.polygon.label,
            ),
            category: customPolygon.category,
          ));
        } else {
          // Reset to default color
          updatedPolygons.add(CustomPolygon(
            polygon: Polygon(
              points: customPolygon.polygon.points,
              color: Colors.blue.withOpacity(0.3),
              borderColor: Colors.blue.withOpacity(0.8),
              borderStrokeWidth: customPolygon.polygon.borderStrokeWidth,
              label: customPolygon.polygon.label,
            ),
            category: customPolygon.category,
          ));
        }
      }
      customPolygons = updatedPolygons;
    } else {
      // Reset all Polygons to default color
      List<CustomPolygon> resetPolygons = [];
      for (var customPolygon in customPolygons) {
        resetPolygons.add(CustomPolygon(
          polygon: Polygon(
            points: customPolygon.polygon.points,
            color: Colors.blue.withOpacity(0.3),
            borderColor: Colors.blue.withOpacity(0.8),
            borderStrokeWidth: customPolygon.polygon.borderStrokeWidth,
            label: customPolygon.polygon.label,
          ),
          category: customPolygon.category,
        ));
      }
      customPolygons = resetPolygons;
    }

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
          if (customPolygons.isNotEmpty)
            PolygonLayer(
              polygons: customPolygons.map((cp) => cp.polygon).toList(),
            ),
          if (geoJsonParser.polylines.isNotEmpty)
            PolylineLayer(polylines: geoJsonParser.polylines),
          MarkerLayer(
            rotate: true,
            markers: [
              if (currentZoom >= 20) ...poiList.map((poi) {
                if (poi['rp'] == userPositionRP) return null;

                final isSelected = poi['rp'] == selectedMarkerRP || poi['rp'] == secondSelectedMarkerRP;
                final isHighlighted = selectedCategory != null && poi['category'] == selectedCategory;

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
                        // Hiển thị marker (Icons.location_on) nếu được chọn HOẶC thuộc category được chọn
                        // Nếu không thì hiển thị dấu chấm tròn nhỏ
                        (isSelected || (isHighlighted && selectedCategory != "Phòng vệ sinh"))
                            ? Icon(
                                Icons.location_on,
                                color: isHighlighted && selectedCategory != "Phòng vệ sinh" ? Colors.green : Colors.red,
                                size: isSelected ? 50 : 30, // Marker lớn hơn nếu được chọn
                              )
                            : Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.withOpacity(0.6), // Màu đỏ mặc định khi không được highlight
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
    if (selectedRoute.length < 2) {
      print("Selected route has less than 2 points, cannot calculate directions.");
      return;
    }

    for (int i = 0; i < selectedRoute.length - 1; i++) {
      double segmentDistance = _calculateDistance(selectedRoute[i], selectedRoute[i + 1]);
      segmentDistances.add(segmentDistance);

      if (i == 0 || selectedRoute.length < 3) {
        // Nếu chỉ có 2 điểm, chỉ cần "Đi thẳng" đến đích
        directions.add("Đi thẳng đến đích");
      } else {
        // Tính hướng dựa trên 3 điểm (trừ đoạn cuối)
        String direction = _getDirection(
            selectedRoute[i - 1], selectedRoute[i], selectedRoute[i + 1]);
        directions.add(direction);
      }
    }

    // Đảm bảo hướng dẫn cuối cùng là "Đến đích"192.168.0.100
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

  void _drawRouteCD(BuildContext context, VoidCallback setStateCallback, {required bool showDirections}) {
    print("Drawing route: startPOI=$startPOI, endPOI=$endPOI");
    if (startPOI != null && endPOI != null) {
      selectedRoute = _findShortestPath(startPOI!, endPOI!);
    }
  }

  void _onPOITap(String rp) {
    if (startPOI == null) {
      startPOI = rp;
    } else if (endPOI == null) {
      endPOI = rp;
      _drawRoute();
    } else {
      startPOI = rp;
      endPOI = null;
      selectedRoute = [];
    }
  }
Widget buildMapSection(BuildContext context, VoidCallback setStateCallback) {
  return FlutterMap(
    mapController: mapController,
    options: MapOptions(
      center: LatLng(11.957103446948263, 108.4451276943349),
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

      // MARKERS LAYER (POIs + User)
      MarkerLayer(
        rotate: true,
        markers: [
          // POI markers
          ...poiList.map((poi) {
            final isSelected = poi['rp'] == selectedMarkerRP || poi['rp'] == secondSelectedMarkerRP;
            return Marker(
              point: poi['coordinates'] as LatLng,
              width: 80.0,
              height: 80.0,
              child: GestureDetector(
                onTap: () {
                  _onPOITap(poi['rp'] as String);
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
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.location_on,
                      color: isSelected ? Colors.green : Colors.red,
                      size: 30,
                    ),
                  ],
                ),
              ),
            );
          }),

          // USER POSITION marker
          Marker(
            point: userPositionCoordinates,
            width: 80.0,
            height: 80.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    "User",
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(
                  Icons.person_pin_circle,
                  color: Colors.blue,
                  size: 30,
                ),
              ],
            ),
          ),
        ],
      ),

      // PATH / ROUTE LINE
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
>>>>>>> 69f9a3dfdfba3e942211dca6015d8e6d36ce7932
}