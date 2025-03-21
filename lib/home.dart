import 'package:flutter/material.dart';
import 'package:flutter_application_1/Location.dart';
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
import 'package:flutter_application_1/ultils/wifi_scanner.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:wifi_scan/wifi_scan.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController mapController = MapController();
  TextEditingController searchPlaceController = TextEditingController();
  int currentPageIndex = 0;
  List<CategoryModel> categories = [];
  List<MapModel> maps = [];
  bool _isDialogDismissed = false; // Kiểm soát việc tắt hộp thoại
  PhotoViewComputedScale _photoViewScale = PhotoViewComputedScale.covered * 1;
  final GeoJsonParser geoJsonParser = GeoJsonParser();
  @override
  void initState() {
    super.initState();
    getCategories();
    getMaps();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showGuideDialog());
    loadGeoJson();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnPOIs());
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
        geoJsonParser.parseGeoJsonAsString(geoJsonData);
        print("Loaded GeoJSON: $path");
      } catch (e) {
        print("Lỗi load GeoJSON từ $path: $e");
      }
    }

    print("Polygons: ${geoJsonParser.polygons.length}");
    print("Polylines: ${geoJsonParser.polylines.length}");
    print("Markers: ${geoJsonParser.markers.length}");

    setState(() {});
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

  void _showPOIDialog(Marker marker) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Thông tin POI"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  "Tọa độ: ${marker.point.latitude}, ${marker.point.longitude}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Đóng"),
            ),
          ],
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
      barrierDismissible: false, // Ngăn chặn đóng hộp thoại khi nhấn ngoài
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
              Expanded(child: _buildMapSection()),
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
                // SizedBox(height: 10),
                // FloatingActionButton(
                //   heroTag: "zoom_button",
                //   onPressed: () {
                //     setState(() {
                //       _photoViewScale = PhotoViewComputedScale.covered * 0;
                //     });
                //   },
                //   backgroundColor: Colors.white,
                //   child: Icon(Icons.map, color: Colors.black),
                // ),
                SizedBox(height: 10), // Khoảng cách giữa các nút
                FloatingActionButton(
                  heroTag: "wifi_scan_button",
                  onPressed: () async {
                    List<WiFiAccessPoint> wifiList =
                        await WifiScanner.scanWiFi();
                    for (var wifi in wifiList) {
                      print("📡 SSID: ${wifi.ssid}, RSSI: ${wifi.level} dBm");
                    }
                  },
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
              hintStyle:
                  GoogleFonts.openSans(color: Colors.grey[00], fontSize: 18),
              //prefixIcon: Icon(Icons.gps_fixed, size: 25, color: Colors.black),
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
        center: LatLng(10.7769, 106.7009),
        zoom: 18,
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
              return Marker(
                width: 40.0,
                height: 40.0,
                point: marker.point,
                child: GestureDetector(
                  onTap: () {
                    _showPOIDialog(marker);
                  },
                  child: Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              );
            }).toList(),
          ),
      ],
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
