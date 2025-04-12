import 'package:flutter/material.dart';
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
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController searchPlaceController = TextEditingController();
  int currentPageIndex = 0;
  List<CategoryModel> categories = [];
  List<MapModel> maps = [];
  bool _isDialogDismissed = false;
  final PhotoViewComputedScale _photoViewScale = PhotoViewComputedScale.covered * 1;
  File? profileImage;
  late POISelectionScreen poiSelectionScreen;

  @override
  void initState() {
    super.initState();
    poiSelectionScreen = POISelectionScreen();
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

// Future<List<int>> getOrderedRSSI(List<String> macList) async {
//   List<WiFiAccessPoint> wifiList = await WifiScanner.scanWiFi();

//   // Tạo map để tra cứu nhanh RSSI theo MAC
//   Map<String, int> wifiMap = {
//     for (var ap in wifiList) ap.bssid.toUpperCase(): ap.level
//   };

//   // Duyệt qua danh sách MAC cố định, lấy RSSI hoặc -100 nếu không tìm thấy
//   List<int> orderedRSSI = macList.map((mac) {
//     return wifiMap[mac.toUpperCase()] ?? -100;
//   }).toList();

//   return orderedRSSI;
// }
// Future<void> sendWiFiDataToServer(List<int> rssiData) async {
//   final url = Uri.parse('http://192.168.1.13:8765/predict');

//   try {
//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'rssi': rssiData}),
//     );

//     if (response.statusCode == 200) {
//       final result = jsonDecode(response.body);
//       String name = result['name'];
//       List coordinates = result['coordinates'];
//       int rp = result['rp'];

//       print("📍 Vị trí dự đoán: $name - RP $rp - Tọa độ $coordinates");

//       // 👉 Cập nhật vị trí trên bản đồ tại đây, ví dụ:
//       updateUserPosition(coordinates); // Tùy bạn xử lý hiển thị
//     } else {
//       print("❌ Lỗi server: ${response.body}");
//     }
//   } catch (e) {
//     print("❌ Gửi dữ liệu thất bại: $e");
//   }
// }

  Future<void> sendWiFiDataToServer() async {
    final url =
        Uri.parse('http://192.168.1.6:8765/predict'); // URL server Node.js

    try {
//     List<String> macAddresses = [
//   "A0:23:B4:11:22:33",
//   "B0:12:FF:44:55:66",
//   "C0:DE:AD:BE:EF:00",
//   // ...
// ];

      // Dữ liệu mẫu WiFi (dùng List thay vì Set)
      final List<int> wifiData = [
        -67,
        -48,
        -61,
        -64,
        -66,
        -92,
        -74,
        -67,
        -55,
        -56,
        -80,
        -74,
        -81,
        -78,
        -84,
        -80,
        -74,
        -78,
        -85,
        -85,
        -68,
        -58,
        -100,
        -65,
        -62,
        -60,
        -65,
        -73,
        -61,
        -84,
        -81,
        -63,
        -64,
        -49,
        -100,
        -100,
        -89,
        -90,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -90,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100,
        -100
     
      ];

      // Gửi dữ liệu đến server
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rssi': wifiData}),
      );

      if (response.statusCode == 200) {
        print("✅ Data sent successfully: ${response.body}");
      } else {
        print("❌ Failed to send data: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error sending data: $e");
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
              if (poiSelectionScreen.startPOI != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Điểm bắt đầu: RP ${poiSelectionScreen.startPOI}",
                      style: TextStyle(fontSize: 16)),
                ),
              if (poiSelectionScreen.endPOI != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Điểm kết thúc: RP ${poiSelectionScreen.endPOI}",
                      style: TextStyle(fontSize: 16)),
                ),
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
                        LatLng(11.957222760551929, 108.44508052756397), 18);
                  },
                  backgroundColor: Colors.yellow,
                  child: Icon(Icons.my_location, color: Colors.black),
                ),
                SizedBox(height: 10),
                // FloatingActionButton(
                //   onPressed: () async {
                //     List<String> macList = [/* danh sách MAC cố định */];
                //     List<int> rssiData = await getOrderedRSSI(macList);
                //     await sendWiFiDataToServer(rssiData);
                //   },
                //   child: Icon(Icons.wifi),
                // ),
                FloatingActionButton(
                  heroTag: "wifi_scan_button",
                  onPressed: () async {
                    List<WiFiAccessPoint> wifiList =
                        await WifiScanner.scanWiFi();
<<<<<<< HEAD
                    for (var wifi in wifiList) {
                      print("📡 SSID: ${wifi.ssid}, RSSI: ${wifi.level} dBm");
=======
                    // for (var wifi in wifiList) {
                    //   print("📡 SSID: ${wifi.bssid}, RSSI: ${wifi.level} dBm");
                    // }

                    // Send WiFi data to the server
                    await sendWiFiDataToServer();

                    String? imagePath;
                    if (imagePath != null) {
                      profileImage = File(imagePath);
>>>>>>> 69f9a3dfdfba3e942211dca6015d8e6d36ce7932
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
      child: TextFormField(
        controller: searchPlaceController,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '   Tìm kiếm địa điểm ...',
          hintStyle: GoogleFonts.openSans(color: Colors.grey[00], fontSize: 18),
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

<<<<<<< HEAD
void main() {
  runApp(MaterialApp(home: HomePage()));
}
=======
// Tạo một StatefulWidget để hiển thị màn hình chọn POI riêng biệt
class POISelectionScreenPage extends StatefulWidget {
  @override
  _POISelectionScreenPageState createState() => _POISelectionScreenPageState();
}

class _POISelectionScreenPageState extends State<POISelectionScreenPage> {
  late POISelectionScreen poiSelectionScreen;

  @override
  void initState() {
    super.initState();
    poiSelectionScreen = POISelectionScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chọn Địa Điểm")),
      body: Column(
        children: [
          if (poiSelectionScreen.startPOI != null)
            Text("Điểm bắt đầu: RP ${poiSelectionScreen.startPOI}",
                style: TextStyle(fontSize: 16)),
          if (poiSelectionScreen.endPOI != null)
            Text("Điểm kết thúc: RP ${poiSelectionScreen.endPOI}",
                style: TextStyle(fontSize: 16)),
          Expanded(
            child: poiSelectionScreen.buildMapSection(context, () {
              setState(() {});
            }),
          ),
        ],
      ),
    );
  }
}
>>>>>>> 69f9a3dfdfba3e942211dca6015d8e6d36ce7932
