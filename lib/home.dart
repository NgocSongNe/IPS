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
import 'dart:convert'; // Import for jsonDecode
import 'package:wifi_scan/wifi_scan.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; // Thêm thư viện TensorFlow Lite
import 'package:tflite_flutter/tflite_flutter.dart' as tfl; // Import thêm alias để sử dụng Interpreter
// Hỗ trợ xử lý dữ liệu

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

  // Danh sách các điểm POI được đọc từ tệp GeoJSON với hệ tọa độ cục bộ oxy
  final List<Map<String, dynamic>> poiPoints = [
    {
      "RP": "1",
      "oxy": [0.0, 0.0],
      "Name": "TV3,4",
      "coordinates": LatLng(11.957103446948263, 108.4451276943349)
    },
    {
      "RP": "2",
      "oxy": [5.0, 0.0],
      "Name": "Cửa ra vào",
      "coordinates": LatLng(11.95722012378778, 108.44507513707596)
    },
    {
      "RP": "3",
      "oxy": [9.5, 0.0],
      "Name": "Hội trường thư viện",
      "coordinates": LatLng(11.957369760112835, 108.445010451218806)
    },
    {
      "RP": "4",
      "oxy": [2.0, 0.5],
      "Name": "Cầu thang",
      "coordinates": LatLng(11.957142339233695, 108.445089287107209)
    },
    {
      "RP": "5",
      "oxy": [2.5, 0.5],
      "Name": "Cầu thang",
      "coordinates": LatLng(11.957153215888788, 108.44508389661911)
    },
    {
      "RP": "6",
      "oxy": [7.0, 0.5],
      "Name": "Cầu thang",
      "coordinates": LatLng(11.957270222302304, 108.445032013171186)
    },
    {
      "RP": "7",
      "oxy": [8.0, 0.5],
      "Name": "Cầu thang",
      "coordinates": LatLng(11.957285713288467, 108.44502527506107)
    },
    {
      "RP": "8",
      "oxy": [1.5, 1.0],
      "Name": "Khu vực tự học",
      "coordinates": LatLng(11.957136406512548, 108.445076821603479)
    },
    {
      "RP": "9",
      "oxy": [8.5, 1.0],
      "Name": "Căn tin",
      "coordinates": LatLng(11.95730021548748, 108.445016852423421)
    },
    {
      "RP": "10",
      "oxy": [2.5, 2.0],
      "Name": "Cầu thang",
      "coordinates": LatLng(11.957142009638083, 108.445051553690533)
    },
    {
      "RP": "11",
      "oxy": [5.0, 2.0],
      "Name": "Cầu thang",
      "coordinates": LatLng(11.957201336842447, 108.445021232195003)
    },
    {
      "RP": "12",
      "oxy": [1.0, 2.5],
      "Name": "Khu vực tự học",
      "coordinates": LatLng(11.957109050074482, 108.445044815580403)
    },
    {
      "RP": "13",
      "oxy": [3.0, 2.5],
      "Name": "Khu vực tự học",
      "coordinates": LatLng(11.957155193462402, 108.445022579817007)
    },
    {
      "RP": "14",
      "oxy": [6.5, 2.5],
      "Name": "Khu vực tự học",
      "coordinates": LatLng(11.957235614776819, 108.44498821545541)
    },
    {
      "RP": "15",
      "oxy": [8.5, 2.5],
      "Name": "Khu vực tự học",
      "coordinates": LatLng(11.95728109895226, 108.44496867493605)
    },
    {
      "RP": "16",
      "oxy": [0.0, 3.0],
      "Name": "Hành lang",
      "coordinates": LatLng(11.957078068081035, 108.445036729848269)
    },
    {
      "RP": "17",
      "oxy": [10.0, 3.0],
      "Name": "Hành lang",
      "coordinates": LatLng(11.957319332021353, 108.444932289141406)
    },
    {
      "RP": "18",
      "oxy": [3.0, 3.5],
      "Name": "Khu vực tự học",
      "coordinates": LatLng(11.957143328020546, 108.444986194022377)
    },
    {
      "RP": "19",
      "oxy": [5.0, 3.5],
      "Name": "Cầu thang",
      "coordinates": LatLng(11.957182220300242, 108.444970022558081)
    },
    {
      "RP": "20",
      "oxy": [2.0, 4.0],
      "Name": "Cầu thang",
      "coordinates": LatLng(11.957113005222325, 108.444984172589329)
    },
    {
      "RP": "21",
      "oxy": [7.5, 4.0],
      "Name": "Cầu thang",
      "coordinates": LatLng(11.957246821023652, 108.444925551031275)
    },
    {
      "RP": "22",
      "oxy": [0.0, 4.5],
      "Name": "Khu vực đọc",
      "coordinates": LatLng(11.957058292338679, 108.44498821545541)
    },
    {
      "RP": "23",
      "oxy": [1.5, 4.5],
      "Name": "Khu vực tự học",
      "coordinates": LatLng(11.957084000803459, 108.444975413046166)
    },
    {
      "RP": "24",
      "oxy": [9.0, 4.5],
      "Name": "Khu vực tự học",
      "coordinates": LatLng(11.957269892706845, 108.444893881913728)
    },
    {
      "RP": "25",
      "oxy": [10.0, 4.5],
      "Name": "Khu vực đọc",
      "coordinates": LatLng(11.957298237914936, 108.444882427126515)
    },
    {
      "RP": "26",
      "oxy": [3.0, 4.5],
      "Name": "Khu vực đọc",
      "coordinates": LatLng(11.957134099343184, 108.44496665350303)
    },
    {
      "RP": "27",
      "oxy": [7.0, 4.5],
      "Name": "Khu vực đọc",
      "coordinates": LatLng(11.957215179854931, 108.444926224842291)
    },
    {
      "RP": "28",
      "oxy": [5.0, 5.0],
      "Name": "Cầu thang",
      "coordinates": LatLng(11.957170354859571, 108.444936332007458)
    },
    {
      "RP": "29",
      "oxy": [2.0, 6.0],
      "Name": "Cầu thang",
      "coordinates": LatLng(11.957100480587288, 108.444947786794671)
    },
    {
      "RP": "30",
      "oxy": [3.0, 6.0],
      "Name": "Khu vực đọc",
      "coordinates": LatLng(11.957124211474238, 108.444937005818488)
    },
    {
      "RP": "31",
      "oxy": [7.0, 6.0],
      "Name": "Khu vực đọc",
      "coordinates": LatLng(11.957205291988943, 108.444901967645862)
    },
    {
      "RP": "32",
      "oxy": [8.0, 6.0],
      "Name": "Cầu thang",
      "coordinates": LatLng(11.957234296394807, 108.444889839047647)
    },
    {
      "RP": "33",
      "oxy": [1.5, 7.0],
      "Name": "Cầu thang tầng 2",
      "coordinates": LatLng(11.957073453741282, 108.444920834354193)
    },
    {
      "RP": "34",
      "oxy": [3.0, 7.0],
      "Name": "Cửa ra vào",
      "coordinates": LatLng(11.957085978377572, 108.444913422433075)
    },
    {
      "RP": "35",
      "oxy": [4.5, 7.0],
      "Name": "Khu vực tự học",
      "coordinates": LatLng(11.957109709265794, 108.444904662889911)
    },
    {
      "RP": "36",
      "oxy": [5.5, 7.0],
      "Name": "Bàn thủ thư",
      "coordinates": LatLng(11.957150579123963, 108.444885796181566)
    },
    {
      "RP": "37",
      "oxy": [6.5, 7.0],
      "Name": "Bàn thủ thư",
      "coordinates": LatLng(11.957176946771117, 108.444872993772336)
    },
    {
      "RP": "38",
      "oxy": [7.5, 7.0],
      "Name": "Khu vực tự học",
      "coordinates": LatLng(11.957194744931497, 108.444864908040202)
    },
    {
      "RP": "39",
      "oxy": [8.0, 7.0],
      "Name": "Phòng tạp chí",
      "coordinates": LatLng(11.957220453383307, 108.444854127064005)
    },
    {
      "RP": "40",
      "oxy": [8.5, 7.0],
      "Name": "Cầu thang tầng 2",
      "coordinates": LatLng(11.957236933158825, 108.444848062764891)
    }
  ];

  @override
  void initState() {
    super.initState();
    getCategories();
    getMaps();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showGuideDialog());

    loadGeoJson().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnPOIs());
    });
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
          // Duyệt qua từng feature trong GeoJSON
          for (var feature in geoJson['features']) {
            final properties = feature['properties'];
            final geometry = feature['geometry'];

            if (geometry['type'] == 'Point') {
              final coordinates = geometry['coordinates'];
              final lat = coordinates[1];
              final lng = coordinates[0];

              geoJsonParser.markers.add(
                Marker(
                  point: LatLng(lat, lng),
                  child: Column(
                    children: [
                      Text(
                        properties['Name'] ?? "POI", // Lấy tên từ thuộc tính "Name"
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
//                 SizedBox(height: 10),
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

                    if (wifiList.isNotEmpty) {
                      // Chuẩn bị dữ liệu đầu vào cho model
                      List<double> inputVector = _prepareInputVector(wifiList);

                      // Chạy model TFLite
                      List<double> outputVector = await _runTFLiteModel(inputVector);

                      // Chuyển đổi tọa độ OXY sang LatLng
                      LatLng userLocation = _convertOXYToLatLng(outputVector);

                      // Hiển thị vị trí trên bản đồ
                      _showUserLocationOnMap(userLocation);
                    } else {
                      print("Không tìm thấy điểm truy cập WiFi nào.");
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
              // Lấy tên từ thuộc tính "Name" trong GeoJSON
              final name = "POI"; // Default name since 'properties' is not available
              return Marker(
                width: 80.0,
                height: 80.0,
                point: marker.point,
                child: Column(
                  children: [
                    Text(
                      name, // Hiển thị tên từ thuộc tính "Name"
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
                      size: 20, // Kích thước nhỏ hơn
                    ),
                  ],
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

  String _determineLocation(List<WiFiAccessPoint> wifiList) {
    // Giả lập logic định vị dựa trên fingerprinting
    for (var wifi in wifiList) {
      if (wifi.ssid.contains("Library")) {
        return "Bạn đang ở gần thư viện.";
      } else if (wifi.ssid.contains("Canteen")) {
        return "Bạn đang ở gần căn tin.";
      }
    }
    return "Không thể xác định vị trí chính xác.";
  }

  void _showLocationDialog(String location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Vị trí của bạn"),
          content: Text(location),
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

  List<double> _prepareInputVector(List<WiFiAccessPoint> wifiList) {
    // Chuẩn bị vector đầu vào cho model
    // Giả sử model yêu cầu vector cố định kích thước (ví dụ: 10 SSID)
    List<double> inputVector = List.filled(10, -100.0); // Giá trị mặc định RSSI
    int index = 0;

    for (var wifi in wifiList) {
      if (index >= 10) break; // Giới hạn số lượng đầu vào
      inputVector[index] = wifi.level.toDouble(); // Chỉ lấy giá trị RSSI
      index++;
    }

    return inputVector;
  }

  Future<List<double>> _runTFLiteModel(List<double> inputVector) async {
    try {
      final interpreter = await tfl.Interpreter.fromAsset('assets/model/wifi_mlp_model.tflite');

      // Chuẩn bị đầu vào và đầu ra
      var input = [inputVector];
      var output = List.filled(1 * 2, 0.0).reshape([1, 2]); // Giả sử đầu ra là [x, y]

      // Chạy model
      interpreter.run(input, output);

      // Đóng interpreter
      interpreter.close();

      // Kiểm tra kết quả đầu ra
      if (output.isEmpty || output[0] == null) {
        throw Exception("Model trả về giá trị null hoặc không hợp lệ");
      }

      return output[0]; // Trả về tọa độ OXY
    } catch (e) {
      print("Lỗi khi chạy model: $e");
      return [0.0, 0.0]; // Trả về giá trị mặc định nếu xảy ra lỗi
    }
  }

  LatLng _convertOXYToLatLng(List<double> oxy) {
    // Tìm tọa độ gốc (originLat, originLng) từ danh sách poiPoints
    final originPoint = poiPoints.firstWhere(
      (point) => point["RP"] == "1", // Giả sử RP "1" là tọa độ gốc
      orElse: () => throw Exception("Không tìm thấy tọa độ gốc trong poiPoints"),
    );

    double originLat = originPoint["coordinates"].latitude;
    double originLng = originPoint["coordinates"].longitude;

    // Tìm điểm tham chiếu từ danh sách poiPoints
    final referencePoint = poiPoints.firstWhere(
      (point) => point["RP"] == "2", // Giả sử RP "2" là điểm tham chiếu
      orElse: () => throw Exception("Không tìm thấy điểm tham chiếu trong poiPoints"),
    );

    double refLat = referencePoint["coordinates"].latitude;
    double refLng = referencePoint["coordinates"].longitude;

    // Lấy tọa độ cục bộ (oxy) của điểm gốc và điểm tham chiếu
    List<double> originOXY = originPoint["oxy"];
    List<double> refOXY = referencePoint["oxy"];

    // Tính khoảng cách trong hệ tọa độ cục bộ
    double localX = refOXY[0] - originOXY[0];
    double localY = refOXY[1] - originOXY[1];

    // Kiểm tra để tránh chia cho 0
    if (localX == 0.0 && localY == 0.0) {
      throw Exception("Khoảng cách cục bộ không hợp lệ (chia cho 0)");
    }

    // Tính tỉ lệ (scale) từ hệ tọa độ cục bộ sang LatLng
    double scaleLat = localY != 0.0 ? (refLat - originLat) / localY : 0.0;
    double scaleLng = localX != 0.0 ? (refLng - originLng) / localX : 0.0;

    // Chuyển đổi từ OXY sang LatLng
    double lat = originLat + oxy[1] * scaleLat;
    double lng = originLng + oxy[0] * scaleLng;

    return LatLng(lat, lng);
  }

  void _showUserLocationOnMap(LatLng location) {
    // Hiển thị vị trí người dùng trên bản đồ
    setState(() {
      geoJsonParser.markers.add(
        Marker(
          width: 40.0,
          height: 40.0,
          point: location,
          child: Icon(Icons.location_on, color: Colors.blue, size: 80),
        ),
      );
    });

    // Di chuyển bản đồ đến vị trí người dùng
    mapController.move(location, 20);
  }

  void testModelWithMockData() async {
    // Dữ liệu giả
    List<int> mockRSSI = [
      -78, -66, -47, -66, -47, -72, -82, -66, -56, -74, -74, -78, -65, -81, -41,
      -68, -77, -65, -77, -74, -69, -67, -77, -74, -85, -72, -58, -93, -84, -63,
      -64, -85, -56, -63, -77, -66, -84, -67, -63, -47, -47
    ];

    // Chuẩn bị vector đầu vào
    List<double> inputVector = List.filled(0, -100.0); // Giá trị mặc định RSSI
    for (int i = 0; i < mockRSSI.length && i < 10; i++) {
      inputVector[i] = mockRSSI[i].toDouble();
    }

    // Chạy model
    List<double> outputVector = await _runTFLiteModel(inputVector);

    // Chuyển đổi tọa độ OXY sang LatLng
    LatLng userLocation = _convertOXYToLatLng(outputVector);

    // In kết quả
    print("Kết quả model (OXY): $outputVector");
    print("Vị trí người dùng (LatLng): $userLocation");
  }
}

extension on List<double> {
  reshape(List<int> list) {}
}
