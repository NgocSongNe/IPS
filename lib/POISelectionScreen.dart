import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:math'; // Required for distance calculations
import 'dart:convert'; // Required for JSON parsing
import 'dart:io'; // Required for file reading

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
      "name": "Cửa chính",
      "coordinates": LatLng(11.95722012378778, 108.44507513707596)
    },
    {
      "name": "Hội trường thư viện",
      "coordinates": LatLng(11.957369760112835, 108.445010451218806)
    },
    {
      "name": "Lối lên TV 3-4",
      "coordinates": LatLng(11.957142339233695, 108.445089287107209)
    },
    {
      "name": "Lối tới  2",
      "coordinates": LatLng(11.957153215888788, 108.44508389661911)
    },
    {
      "name": "Cầu thang 3",
      "coordinates": LatLng(11.957270222302304, 108.445032013171186)
    },
    {
      "name": "Cầu thang 4",
      "coordinates": LatLng(11.957285713288467, 108.44502527506107)
    },
    {
      "name": "Khu vực tự học 1",
      "coordinates": LatLng(11.957136406512548, 108.445076821603479)
    },
    {
      "name": "Căn tin",
      "coordinates": LatLng(11.95730021548748, 108.445016852423421)
    },
    {
      "name": "Cầu thang 5",
      "coordinates": LatLng(11.957142009638083, 108.445051553690533)
    },
    {
      "name": "Cầu thang 6",
      "coordinates": LatLng(11.957201336842447, 108.445021232195003)
    },
    {
      "name": "Khu vực tự học 2",
      "coordinates": LatLng(11.957109050074482, 108.445044815580403)
    },
    {
      "name": "Khu vực tự học 3",
      "coordinates": LatLng(11.957155193462402, 108.445022579817007)
    },
    {
      "name": "Khu vực tự học 4",
      "coordinates": LatLng(11.957235614776819, 108.44498821545541)
    },
    {
      "name": "Khu vực tự học 5",
      "coordinates": LatLng(11.95728109895226, 108.44496867493605)
    },
    {
      "name": "Hành lang 1",
      "coordinates": LatLng(11.957078068081035, 108.445036729848269)
    },
    {
      "name": "Hành lang 2",
      "coordinates": LatLng(11.957319332021353, 108.444932289141406)
    },
    {
      "name": "Khu vực tự học 6",
      "coordinates": LatLng(11.957143328020546, 108.444986194022377)
    },
    {
      "name": "Cầu thang 7",
      "coordinates": LatLng(11.957182220300242, 108.444970022558081)
    },
    {
      "name": "Cầu thang 8",
      "coordinates": LatLng(11.957113005222325, 108.444984172589329)
    },
    {
      "name": "Cầu thang 9",
      "coordinates": LatLng(11.957246821023652, 108.444925551031275)
    },
    {
      "name": "Khu vực đọc 1",
      "coordinates": LatLng(11.957058292338679, 108.44498821545541)
    },
    {
      "name": "Khu vực tự học 7",
      "coordinates": LatLng(11.957084000803459, 108.444975413046166)
    },
    {
      "name": "Khu vực tự học 8",
      "coordinates": LatLng(11.957269892706845, 108.444893881913728)
    },
    {
      "name": "Khu vực đọc 2",
      "coordinates": LatLng(11.957298237914936, 108.444882427126515)
    },
    {
      "name": "Khu vực đọc 3",
      "coordinates": LatLng(11.957134099343184, 108.44496665350303)
    },
    {
      "name": "Khu vực đọc 4",
      "coordinates": LatLng(11.957215179854931, 108.444926224842291)
    },
    {
      "name": "Cầu thang 10",
      "coordinates": LatLng(11.957170354859571, 108.444936332007458)
    },
    {
      "name": "Cầu thang 11",
      "coordinates": LatLng(11.957100480587288, 108.444947786794671)
    },
    {
      "name": "Khu vực đọc 5",
      "coordinates": LatLng(11.957124211474238, 108.444937005818488)
    },
    {
      "name": "Khu vực đọc 6",
      "coordinates": LatLng(11.957205291988943, 108.444901967645862)
    },
    {
      "name": "Cầu thang 12",
      "coordinates": LatLng(11.957234296394807, 108.444889839047647)
    },
    {
      "name": "Cầu thang tầng 2 1",
      "coordinates": LatLng(11.957073453741282, 108.444920834354193)
    },
    {
      "name": "Cửa ra vào 2",
      "coordinates": LatLng(11.957085978377572, 108.444913422433075)
    },
    {
      "name": "Khu vực tự học 9",
      "coordinates": LatLng(11.957109709265794, 108.444904662889911)
    },
    {
      "name": "Bàn thủ thư",
      "coordinates": LatLng(11.95716376294754, 108.44487939497695)
    },
    {
      "name": "Khu vực tự học 10",
      "coordinates": LatLng(11.957194744931497, 108.444864908040202)
    },
    {
      "name": "Phòng tạp chí",
      "coordinates": LatLng(11.957220453383307, 108.444854127064005)
    },
    {
      "name": "Cầu thang tầng 2 2",
      "coordinates": LatLng(11.957236933158825, 108.444848062764891)
    },
  ];
  List<LatLng> selectedRoute = [];

  late Map<String, List<Map<String, dynamic>>> graph;
  List<List<LatLng>> walls = []; // Danh sách các tường từ wallList

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

  @override
  void initState() {
    super.initState();
    _loadWallsFromWallList(); // Đọc tường từ wallList
    graph = _generateGraph();
  }

  /// Đọc dữ liệu từ wallList để lấy danh sách tường
  void _loadWallsFromWallList() {
    setState(() {
      walls = wallList.map((wall) {
        return wall['coordinates'] as List<LatLng>;
      }).toList();
    });

    // Ghi danh sách tường vào console để kiểm tra
    print("Extracted Walls from wallList:");
    for (var wall in walls) {
      print(wall.map((point) => "(${point.latitude}, ${point.longitude})").toList());
    }
  }

  /// Tạo đồ thị từ danh sách POI và kiểm tra tường
  Map<String, List<Map<String, dynamic>>> _generateGraph() {
    Map<String, List<Map<String, dynamic>>> generatedGraph = {};

    for (var poi in poiList) {
      String poiName = poi["name"];
      generatedGraph[poiName] = [];
      LatLng coordinates = poi["coordinates"];

      for (var otherPoi in poiList) {
        if (otherPoi == poi) continue;
        String otherName = otherPoi["name"];
        LatLng otherCoordinates = otherPoi["coordinates"];

        // Kiểm tra xem đoạn đường có cắt qua tường không
        if (!_isPathBlocked(coordinates, otherCoordinates)) {
          double distance = _calculateDistance(coordinates, otherCoordinates);
          generatedGraph[poiName]!.add({"name": otherName, "distance": distance});
        }
      }
    }
    return generatedGraph;
  }

  /// Kiểm tra xem đoạn đường có cắt qua bất kỳ tường nào không
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

  /// Kiểm tra xem hai đoạn thẳng có cắt nhau không
  bool _doLinesIntersect(LatLng p1, LatLng q1, LatLng p2, LatLng q2) {
    int orientation(LatLng a, LatLng b, LatLng c) {
      double value = (b.latitude - a.latitude) * (c.longitude - b.longitude) -
          (b.longitude - a.longitude) * (c.latitude - b.latitude);
      if (value == 0) return 0; // Thẳng hàng
      return (value > 0) ? 1 : 2; // 1: Thuận chiều kim đồng hồ, 2: Ngược chiều
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

    // Kiểm tra các trường hợp giao nhau
    if (o1 != o2 && o3 != o4) return true;

    // Kiểm tra các trường hợp đặc biệt (thẳng hàng)
    if (o1 == 0 && onSegment(p1, p2, q1)) return true;
    if (o2 == 0 && onSegment(p1, q2, q1)) return true;
    if (o3 == 0 && onSegment(p2, p1, q2)) return true;
    if (o4 == 0 && onSegment(p2, q1, q2)) return true;

    return false;
  }

  /// Thuật toán Dijkstra để tìm đường đi ngắn nhất
  List<LatLng> _findShortestPath(String start, String end) {
    if (!graph.containsKey(start) || !graph.containsKey(end)) {
      print("Start or end POI not found in the graph.");
      return [];
    }

    final Map<String, double> distances = {};
    final Map<String, String?> previous = {};
    final List<String> unvisited = [];

    // Khởi tạo khoảng cách và danh sách chưa thăm
    for (var node in graph.keys) {
      distances[node] = double.infinity;
      previous[node] = null;
      unvisited.add(node);
    }
    distances[start] = 0;

    while (unvisited.isNotEmpty) {
      // Tìm nút có khoảng cách nhỏ nhất
      unvisited.sort((a, b) => distances[a]!.compareTo(distances[b]!));
      final current = unvisited.removeAt(0);

      if (current == end) break;

      for (var neighbor in graph[current]!) {
        final newDist = distances[current]! + neighbor['distance'];
        if (newDist < distances[neighbor['name']]!) {
          distances[neighbor['name']] = newDist;
          previous[neighbor['name']] = current;
        }
      }
    }

    // Dựng lại đường đi
    final path = <String>[];
    var current = end;
    while (current.isNotEmpty) {
      path.insert(0, current);
      current = previous[current] ?? '';
    }

    // Chuyển đổi danh sách tên POI thành danh sách tọa độ
    return path.map((name) {
      return poiList.firstWhere((poi) => poi['name'] == name)['coordinates'] as LatLng;
    }).toList();
  }

  /// Hàm tính khoảng cách giữa hai điểm (Haversine Formula)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371; // Bán kính Trái Đất (km)
    double dLat = (point2.latitude - point1.latitude) * (pi / 180);
    double dLon = (point2.longitude - point1.longitude) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(point1.latitude * (pi / 180)) *
            cos(point2.latitude * (pi / 180)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c * 1000; // Trả về khoảng cách tính bằng mét
  }

  /// Vẽ tuyến đường trên bản đồ
  void _drawRoute() {
    if (startPOI != null && endPOI != null) {
      setState(() {
        selectedRoute = _findShortestPath(startPOI!, endPOI!);
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
                // Hiển thị các tường từ wallList
                PolylineLayer(
                  polylines: walls.map((wall) {
                    return Polyline(
                      points: wall,
                      color: Colors.black,
                      strokeWidth: 2.0,
                    );
                  }).toList(),
                ),
                // Hiển thị kết quả của thuật toán dẫn đường
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