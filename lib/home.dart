import 'package:flutter/material.dart';
import 'package:flutter_application_1/account.dart';
import 'package:flutter_application_1/information.dart';
import 'package:flutter_application_1/models/category_model.dart';
import 'package:flutter_application_1/models/map_model.dart';
import 'package:flutter_application_1/POISelectionScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:wifi_scan/wifi_scan.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController mapController = MapController();
  TextEditingController searchPlaceController = TextEditingController();
  int currentPageIndex = 0;
  bool showLabel = true;
  List<CategoryModel> categories = [];
  List<MapModel> maps = [];
  bool _isDialogDismissed = false;
  final PhotoViewComputedScale _photoViewScale =
      PhotoViewComputedScale.covered * 1;
  final GeoJsonParser geoJsonParser = GeoJsonParser();

  final Map<String, Map<String, dynamic>> poiDetails = {
    "Hội trường Thư viện": {
      "description":
          "Không gian rộng lớn, thường được sử dụng để tổ chức các buổi hội thảo, thuyết trình, các buổi hội họp, triển lãm và các sự kiện lớn của thư viện và các đơn vị, tổ chức và doanh nghiệp.",
      "images": [
        "https://via.placeholder.com/150",
        "https://via.placeholder.com/150",
        "https://via.placeholder.com/150",
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    getCategories();
    getMaps();

    // Thêm try-catch để bắt lỗi khi khởi tạo
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGuideDialog();
        loadGeoJson().then((_) => _focusOnPOIs());
      });
    } catch (e) {
      print("Lỗi khởi tạo: $e");
    }
  }

  Future<void> loadGeoJson() async {
    try {
      List<String> geoJsonFiles = [
        "assets/geojson/Room.geojson",
        "assets/geojson/Wall.geojson",
        "assets/geojson/Hallways.geojson",
        "assets/geojson/Doors.geojson",
        "assets/geojson/POI.geojson",
      ];

      // Kiểm tra tất cả file có tồn tại không
      for (String path in geoJsonFiles) {
        try {
          await rootBundle.loadString(path);
        } catch (e) {
          print("File không tồn tại: $path");
          // Tiếp tục với file tiếp theo
          continue;
        }
      }

      for (String path in geoJsonFiles) {
        try {
          String geoJsonData = await rootBundle.loadString(path);
          final geoJson = jsonDecode(geoJsonData);
          if (geoJson['features'] is List) {
            for (var feature in geoJson['features']) {
              final properties = feature['properties'];
              final geometry = feature['geometry'];

              if (geometry['type'] == 'Point' &&
                  path == "assets/geojson/POI.geojson") {
                final coordinates = geometry['coordinates'];
                final lat = coordinates[1];
                final lng = coordinates[0];
                final name = properties['Name'] ?? 'Unknown';

                geoJsonParser.markers.add(
                  Marker(
                    point: LatLng(lat, lng),
                    width: 80.0,
                    height: 80.0,
                    child: GestureDetector(
                      onTap: () {
                        final details = poiDetails[name] ?? {};
                        _showPOIDetailsDialog(
                          name: name,
                          description:
                              details['description'] ?? 'Không có mô tả',
                          images: details['images']?.cast<String>() ?? [],
                        );
                      },
                      child: Column(
                        children: [
                          if (showLabel)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
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

      print("Polygons: ${geoJsonParser.polygons.length}");
      print("Polylines: ${geoJsonParser.polylines.length}");
      print("Markers: ${geoJsonParser.markers.length}");

      setState(() {});
    } catch (e) {
      print("Lỗi load GeoJSON: $e");
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

      setState(() {
        mapController.fitBounds(bounds,
            options: FitBoundsOptions(padding: EdgeInsets.all(50)));
      });
    }
  }

  void _showPOIDetailsDialog({
    required String name,
    required String description,
    required List<String> images,
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
                      print("Đường đi pressed");
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
                      print("Bắt đầu pressed");
                    },
                    icon: Icon(Icons.navigation, color: Colors.white),
                    label: Text(
                      "Bắtt đầu",
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
                    : Center(child: Text("Không có hình ảnh")),
              ),
            ],
          ),
        );
      },
    );
  }

  void getCategories() {
    categories = CategoryModel.getCategories();
  }

  void getMaps() {
    maps = MapModel.getMaps();
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Vuốt để di chuyển",
                  style: GoogleFonts.openSans(fontSize: 18)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left, size: 30),
                  Icon(Icons.swipe, size: 50),
                  Icon(Icons.chevron_right, size: 30),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Future.delayed(Duration(milliseconds: 300), () {
                    setState(() {
                      _isDialogDismissed = true;
                    });
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text("OK",
                    style: GoogleFonts.openSans(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFEBCD),
      bottomNavigationBar: _bottomNavBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _searchField(),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _categoryButton('Kệ sách', Icons.book),
                      _categoryButton('Khu vực đọc', Icons.menu_book),
                      _categoryButton('Phòng vệ sinh', Icons.people),
                      _categoryButton('Căn tin', Icons.food_bank),
                      _categoryButton('Phòng học', Icons.class_),
                      _categoryButton('Phòng thí nghiệm', Icons.science),
                      _categoryButton('Phòng máy tính', Icons.computer),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: _buildMapSection(),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "location_button",
                  onPressed: () {
                    mapController.move(
                        LatLng(11.957222760551929, 108.44508052756397), 18);
                  },
                  backgroundColor: Colors.yellow,
                  child: Icon(Icons.my_location, color: Colors.black),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "wifi_scan_button",
                  onPressed: _scanWiFi,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.wifi, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      margin: EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          )
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => POISelectionScreen()),
          );
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: searchPlaceController,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '   Tìm kiếm địa điểm ...',
              hintStyle: GoogleFonts.openSans(color: Colors.grey, fontSize: 18),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.mic, color: Colors.black),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryButton(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: Colors.black),
        label: Text(title, style: GoogleFonts.openSans(color: Colors.black)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        // Điều chỉnh tọa độ mặc định về khu vực Đà Lạt
        center: LatLng(11.957222760551929, 108.44508052756397),
        zoom: 18,
        minZoom: 3,
        maxZoom: 22,
        keepAlive: true,
        onTap: (tapPosition, point) {
          // Xử lý tap trên map
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
          // Thêm các tùy chọn để cải thiện hiệu suất
          tileProvider: NetworkTileProvider(),
          maxNativeZoom: 19,
          keepBuffer: 5,
          backgroundColor: Colors.transparent,
        ),
        if (geoJsonParser.polygons.isNotEmpty)
          PolygonLayer(polygons: geoJsonParser.polygons),
        if (geoJsonParser.polylines.isNotEmpty)
          PolylineLayer(polylines: geoJsonParser.polylines),
        if (geoJsonParser.markers.isNotEmpty)
          MarkerLayer(
            markers: geoJsonParser.markers,
            rotate: true,
          ),
      ],
    );
  }

  // Cải thiện việc scan WiFi
  Future<void> _scanWiFi() async {
    try {
      // Kiểm tra quyền truy cập
      var can = await WiFiScan.instance.canStartScan();
      if (can != CanStartScan.yes) {
        throw Exception("Không thể quét WiFi: $can");
      }

      // Thực hiện quét
      var result = await WiFiScan.instance.startScan();
      if (!result) {
        throw Exception("Quét WiFi thất bại");
      }

      // Lấy kết quả
      List<WiFiAccessPoint> accessPoints =
          await WiFiScan.instance.getScannedResults();

      // Hiển thị dialog với kết quả
      _showWiFiResultsDialog(accessPoints);
    } catch (e) {
      print("Lỗi khi quét WiFi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể quét WiFi: $e")),
      );
    }
  }

  void _showWiFiResultsDialog(List<WiFiAccessPoint> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kết quả quét WiFi'),
        content: SingleChildScrollView(
          child: Column(
            children: results
                .map((wifi) => ListTile(
                      title: Text(wifi.ssid),
                      subtitle: Text('Strength: ${wifi.level} dBm'),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  NavigationBar _bottomNavBar() {
    return NavigationBar(
      onDestinationSelected: (int index) {
        if (index != currentPageIndex) {
          setState(() {
            currentPageIndex = index;
          });
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InformationPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AccountPage()),
            );
          }
        }
      },
      indicatorColor: Colors.amber,
      selectedIndex: currentPageIndex,
      destinations: [
        NavigationDestination(
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Badge(child: Icon(Icons.book_online_outlined)),
          label: 'Thông tin',
        ),
        NavigationDestination(
          icon: Badge(child: Icon(Icons.manage_accounts_outlined)),
          label: 'Tài khoản',
        ),
      ],
    );
  }
}
