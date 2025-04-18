import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:flutter_application_1/ultils/permission.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController searchPlaceController = TextEditingController();
  int currentPageIndex = 0;
  bool showLabel = true;
  List<CategoryModel> categories = [];
  List<MapModel> maps = [];
  bool _isDialogDismissed = false;
  PhotoViewComputedScale _photoViewScale = PhotoViewComputedScale.covered * 1;
  File? profileImage;

  late POISelectionScreen poiSelectionScreen;

  LatLng userPositionCoordinates = LatLng(
      11.95722012378790, 108.44507513707570); // Tọa độ mặc định cho người dùng
  String? selectedMarkerRP;

  Timer? wifiScanTimer;

  String? selectedCategory;
  @override
  void initState() {
    super.initState();
    poiSelectionScreen = POISelectionScreen(
        userPositionCoordinates: userPositionCoordinates,
        selectedCategory: selectedCategory,
        context: context,
        startWifiTracking: startWifiTracking,
        stopWifiTracking:
            stopWifiTracking); // Initialize POISelectionScreen with user position coordinates
    getCategories();
    getMaps();

    requestPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) => _showGuideDialog());
  }

  Future<void> startWifiTracking() async {
    // Bắt đầu quét Wi-Fi mỗi 5 giây
    wifiScanTimer = Timer.periodic(Duration(seconds: 15), (timer) async {
      // Quét Wi-Fi và gửi dữ liệu
      await sendWiFiDataToServer();
      print("✅ Đã quét Wi-Fi và gửi dữ liệu đến server");
    });
  }

// Hàm dừng quét Wi-Fi
  Future<void> stopWifiTracking() async {
    if (wifiScanTimer != null && wifiScanTimer!.isActive) {
      wifiScanTimer?.cancel(); // Hủy Timer để dừng quét
      print("❌ Dừng quét Wi-Fi");
    }
  }

  void getCategories() {
    categories = CategoryModel.getCategories();
  }

  void getMaps() {
    maps = MapModel.getMaps();
  }

  void _showGuideDialog() async {
    // Lấy instance của SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // Kiểm tra xem bảng đã được hiển thị chưa
    bool hasShownGuide = prefs.getBool('hasShownSwipeGuide') ?? false;

    if (!hasShownGuide) {
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
                Text(
                  "Vuốt để di chuyển",
                  style: GoogleFonts.openSans(fontSize: 18),
                ),
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
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Lưu trạng thái đã hiển thị
                    await prefs.setBool('hasShownSwipeGuide', true);
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
                  child: Text(
                    "OK",
                    style: GoogleFonts.openSans(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // ... các hàm khác giữ nguyên ...
  }

  Future<void> sendWiFiDataToServer() async {
    final url = Uri.parse('http://192.168.1.11/predict'); // URL server Node.js

    try {
      // Quét các mạng Wi-Fi xung quanh
      var wifiNetworks = await WifiScanner.scanWiFi();

      // Kiểm tra xem có mạng Wi-Fi nào được quét không
      if (wifiNetworks.isEmpty) {
        print("❌ Không tìm thấy mạng Wi-Fi");
        return; // Nếu không có mạng, dừng hàm
      }

      // Danh sách các địa chỉ MAC cố định mà bạn muốn lấy dữ liệu RSSI
      List<String> macAddresses = [
        "88:dc:97:12:62:cf",
        "8e:dc:97:12:65:63",
        "8e:dc:97:12:65:21",
        "8e:dc:97:12:65:64",
        "8e:dc:97:12:65:2b",
        "88:dc:97:12:64:c4",
        "88:dc:97:12:62:c6",
        "8e:dc:97:12:62:cf",
        "b4:5d:50:d7:e9:51",
        "b4:5d:50:d7:e9:50",
        "88:dc:97:12:62:c7",
        "8e:dc:97:12:65:22",
        "88:dc:97:12:65:57",
        "88:dc:97:12:64:82",
        "88:dc:97:12:64:83",
        "8e:dc:97:12:62:c7",
        "8e:dc:97:12:62:c6",
        "8e:dc:97:12:64:82",
        "8e:dc:97:12:64:83",
        "88:dc:97:12:65:58",
        "88:dc:97:12:65:2b",
        "88:dc:97:12:65:2a",
        "8e:dc:97:12:64:c4",
        "88:dc:97:12:62:d0",
        "b4:5d:50:d7:e9:40",
        "8e:dc:97:12:65:2a",
        "8e:dc:97:12:62:d0",
        "88:dc:97:12:65:22",
        "88:dc:97:12:65:21",
        "8e:dc:97:12:65:58",
        "8e:dc:97:12:65:57",
        "b4:5d:50:d7:e9:41",
        "88:dc:97:12:65:64",
        "88:dc:97:12:65:63"
      ];

      // Tạo một map MAC address với RSSI
      Map<String, int> macToRssi = {};
      // Duyệt qua các mạng Wi-Fi quét được và lưu RSSI vào map
      for (var wifi in wifiNetworks) {
        if (macAddresses.contains(wifi.bssid)) {
          macToRssi[wifi.bssid] =
              wifi.level; // Lưu RSSI của mạng Wi-Fi với MAC address
        }
      }

      // Xóa dữ liệu cũ và cập nhật lại danh sách RSSI
      List<int> wifiData = [];
      wifiData.clear();
      // Cập nhật lại dữ liệu wifiData mỗi lần quét
      for (var mac in macAddresses) {
        wifiData.add(macToRssi[mac] ?? -100); // Nếu không có mạng, gán -100
      }

      // In ra mảng wifiData để kiểm tra các giá trị RSSI quét được
      print("Quét được dữ liệu RSSI: $wifiData");

      // Định dạng dữ liệu RSSI theo yêu cầu của bạn
      Map<String, dynamic> dataToSend = {
        'rssi': wifiData, // Mảng các giá trị RSSI
      };

      // Gửi dữ liệu đến server
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dataToSend), // Gửi dữ liệu RSSI dưới dạng JSON
      );

      if (response.statusCode == 200) {
        print("✅ Dữ liệu đã được gửi thành công: ${response.body}");

        // Xử lý dữ liệu trả về từ server
        var responseData = jsonDecode(response.body);
        String name = responseData['name'];
        List coordinates = responseData['coordinates'];
        int rp = responseData['rp'];

        // Cập nhật vị trí người dùng từ dự đoán của model
        setState(() {
          userPositionCoordinates = LatLng(
              coordinates[1], coordinates[0]); // Tọa độ từ dữ liệu trả về
          selectedMarkerRP =
              rp.toString(); // Cập nhật lại marker người dùng với tọa độ mới
        });

        // Di chuyển bản đồ đến vị trí người dùng
        poiSelectionScreen.mapController.move(userPositionCoordinates, 30);
      } else {
        print("❌ Gửi dữ liệu thất bại: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Lỗi khi quét và gửi dữ liệu Wi-Fi: $e");
    }
  }

  Widget _categoriesMethod() {
    return Container(
      height: 50, // Set container height
      child: SingleChildScrollView(
        // Horizontal scrolling
        scrollDirection: Axis.horizontal, // Scroll horizontally
        child: Row(
          children: List.generate(categories.length, (index) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    selectedCategory = categories[index].name;
                    print('selectedCategory ${selectedCategory}');
                    poiSelectionScreen.selectedCategory =
                        selectedCategory; // Cập nhật category được chọn
                  });
                },
                icon: Icon(
                  categories[index].icons.icon, // Get category icon
                  color: Colors.green,
                ),
                label: Text(
                  categories[index].name,
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 255, 255, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(100, 40),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<CategoryModel> categories = CategoryModel.getCategories();
    List<WiFiAccessPoint> wifiList = [];
    return Scaffold(
      backgroundColor: Color(0xffFFEBCD),
      bottomNavigationBar: _bottomNavBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _searchField(),
              SizedBox(height: 5),
              _categoriesMethod(),
              SizedBox(height: 10),
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
                  onPressed: () async {
                    wifiList = await WifiScanner.scanWiFi();
                    if (kDebugMode) {
                      for (var wifi in wifiList) {
                        print("SSID: ${wifi.ssid}, RSSI: ${wifi.level}");
                      }
                    }
                    await sendWiFiDataToServer();

                    String? imagePath;
                    if (imagePath != null) {
                      profileImage = File(imagePath);
                    }
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

                // Button để bắt đầu quét Wi-Fi
                FloatingActionButton(
                  heroTag: "stop_wifi_button",
                  onPressed: () {
                    // Dừng quét Wi-Fi
                    stopWifiTracking();
                  },
                  backgroundColor: Colors.red,
                  child: Icon(Icons.stop, color: Colors.white),
                ),
                SizedBox(height: 10),
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
              builder: (context) => SuggestedPlacesScreen(
                poiSelectionScreen: poiSelectionScreen,
                sourcePage: 'HomePage', // Truyền sourcePage
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
                  GoogleFonts.openSans(color: Colors.grey[700], fontSize: 18),
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
              MaterialPageRoute(
                builder: (context) => InformationPage(
                  poiSelectionScreen:
                      poiSelectionScreen, // Truyền poiSelectionScreen
                ),
              ),
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
      ],
    );
  }
}

class POISelectionScreenPage extends StatefulWidget {
  final LatLng userPositionCoordinates; // Accept the user position coordinates
  final Function startWifiTracking;
  final Function stopWifiTracking;
  String? selectedCategory;
  POISelectionScreenPage(
      {required this.userPositionCoordinates,
      this.selectedCategory,
      context,
      required this.startWifiTracking,
      required this.stopWifiTracking}); // Constructor

  @override
  _POISelectionScreenPageState createState() => _POISelectionScreenPageState();
}

class _POISelectionScreenPageState extends State<POISelectionScreenPage> {
  late POISelectionScreen poiSelectionScreen;

  @override
  void initState() {
    super.initState();
    poiSelectionScreen = POISelectionScreen(
        userPositionCoordinates: widget.userPositionCoordinates,
        selectedCategory: widget.selectedCategory,
        context: context,
        startWifiTracking: widget.startWifiTracking,
        stopWifiTracking: widget
            .stopWifiTracking); // Initialize POISelectionScreen with user position coordinates
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
