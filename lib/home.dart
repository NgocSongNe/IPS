import 'package:flutter/material.dart';
import 'package:flutter_application_1/Location.dart';
import 'package:flutter_application_1/account.dart';
import 'package:flutter_application_1/information.dart';
import 'package:flutter_application_1/models/category_model.dart';
import 'package:flutter_application_1/models/map_model.dart';
import 'package:flutter_application_1/POISelectionScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:photo_view/photo_view.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'dart:io';
import 'package:flutter_application_1/ultils/wifi_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController searchPlaceController = TextEditingController();
  int currentPageIndex = 0;
  List<CategoryModel> categories = [];
  List<MapModel> maps = [];
  bool _isDialogDismissed = false;
  PhotoViewComputedScale _photoViewScale = PhotoViewComputedScale.covered * 1;
  File? profileImage;
  late POISelectionScreen poiSelectionScreen;

  // Tọa độ mặc định cho người dùng
  LatLng userPositionCoordinates = LatLng(11.957222760551929, 108.44508052756397);

  @override
  void initState() {
    super.initState();
    // Khởi tạo POISelectionScreen với tọa độ và context
    poiSelectionScreen = POISelectionScreen(
      userPositionCoordinates: userPositionCoordinates,
      context: context,
    );
    getCategories();
    getMaps();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showGuideDialog());
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

  Future<List<int>> getOrderedRSSI(List<String> macList) async {
    List<WiFiAccessPoint> wifiList = await WifiScanner.scanWiFi();
    Map<String, int> wifiMap = {
      for (var ap in wifiList) ap.bssid.toUpperCase(): ap.level
    };
    List<int> orderedRSSI = macList.map((mac) {
      return wifiMap[mac.toUpperCase()] ?? -100;
    }).toList();
    return orderedRSSI;
  }

  Future<void> sendWiFiDataToServer() async {
    final url = Uri.parse('http://192.168.1.6:8765/predict');
    final List<String> macList = [
      // Thêm danh sách MAC thực tế của bạn, ví dụ:
      "A0:23:B4:11:22:33",
      "B0:12:FF:44:55:66",
      "C0:DE:AD:BE:EF:00",
      // Thêm các MAC khác nếu cần
    ];

    try {
      List<int> rssiData = await getOrderedRSSI(macList);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rssi': rssiData}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        String name = result['name'];
        List coordinates = result['coordinates'];
        int rp = result['rp'];

        print("📍 Vị trí dự đoán: $name - RP $rp - Tọa độ $coordinates");

        // Cập nhật tọa độ người dùng
        setState(() {
          userPositionCoordinates = LatLng(coordinates[1], coordinates[0]);
          poiSelectionScreen = POISelectionScreen(
            userPositionCoordinates: userPositionCoordinates,
            context: context,
          );
        });
      } else {
        print("❌ Lỗi server: ${response.body}");
      }
    } catch (e) {
      print("❌ Gửi dữ liệu thất bại: $e");
    }
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
                child: poiSelectionScreen.buildMapSection(context, () {
                  setState(() {});
                }),
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
                    poiSelectionScreen.mapController.move(
                        userPositionCoordinates, 18);
                  },
                  backgroundColor: Colors.yellow,
                  child: Icon(Icons.my_location, color: Colors.black),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "wifi_scan_button",
                  onPressed: () async {
                    await sendWiFiDataToServer();
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
            MaterialPageRoute(
              builder: (context) => POISelectionScreenPage(
                poiSelectionScreen: poiSelectionScreen,
              ),
            ),
          );
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: searchPlaceController,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '   Tìm kiếm địa điểm ...',
              hintStyle:
                  GoogleFonts.openSans(color: Colors.grey[600], fontSize: 18),
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

class POISelectionScreenPage extends StatefulWidget {
  final POISelectionScreen poiSelectionScreen;

  const POISelectionScreenPage({Key? key, required this.poiSelectionScreen})
      : super(key: key);

  @override
  _POISelectionScreenPageState createState() => _POISelectionScreenPageState();
}

class _POISelectionScreenPageState extends State<POISelectionScreenPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chọn Địa Điểm")),
      body: Column(
        children: [
          if (widget.poiSelectionScreen.startPOI != null)
            Text("Điểm bắt đầu: RP ${widget.poiSelectionScreen.startPOI}",
                style: TextStyle(fontSize: 16)),
          if (widget.poiSelectionScreen.endPOI != null)
            Text("Điểm kết thúc: RP ${widget.poiSelectionScreen.endPOI}",
                style: TextStyle(fontSize: 16)),
          Expanded(
            child: widget.poiSelectionScreen.buildMapSection(context, () {
              setState(() {});
            }),
          ),
        ],
      ),
    );
  }
}