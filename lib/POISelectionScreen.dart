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
  double currentZoom = 18.0;
  String? startPOI;
  String? endPOI;

  List<Map<String, dynamic>> poiList = [];
  List<LatLng> selectedRoute = [];
  late Map<String, List<Map<String, dynamic>>> graph;
  List<List<LatLng>> walls = [];
  final GeoJsonParser geoJsonParser = GeoJsonParser();

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
      "/geojson/Paths",
    ];

    for (String endpoint in geoJsonEndpoints) {
      try {
        final response = await http.get(Uri.parse("http://localhost:5000$endpoint"));
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

  Future<void> _loadPOIData() async {
    try {
      final response = await http.get(Uri.parse("http://localhost:5000/geojson/POI"));
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

  Future<void> _loadWallsFromAPI() async {
    try {
      final response = await http.get(Uri.parse("http://localhost:5000/geojson/Paths"));
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

  void _drawRoute() {
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

  Widget buildMapSection(VoidCallback setStateCallback) {
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
        MarkerLayer(
          markers: poiList.map((poi) {
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
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        poi['name'] ?? "Unknown",
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