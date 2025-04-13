import 'package:flutter/foundation.dart';
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
import 'package:flutter_application_1/ultils/permission.dart';
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
  LatLng userPositionCoordinates = LatLng(11.95722012378790, 108.44507513707570); // Tọa độ mặc định cho người dùng
  String? selectedMarkerRP;
      Timer? wifiScanTimer;
  @override
  void initState() {
    super.initState();
    poiSelectionScreen = POISelectionScreen(userPositionCoordinates: userPositionCoordinates,context: context);
    getCategories();
    getMaps();
    scanAndSendWiFiData(); 
    requestPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) => _showGuideDialog());
  }
  Future<void> scanAndSendWiFiData() async {
    try {
      // Quét mạng Wi-Fi
      List<WiFiAccessPoint> wifiList = await WifiScanner.scanWiFi();
      
      // Lấy các giá trị RSSI từ danh sách Wi-Fi
      List<int> wifiData = wifiList.map((wifi) => wifi.level).toList();

      // Gửi dữ liệu Wi-Fi lên server
      final url = Uri.parse('http://192.168.0.100:8765/predict'); // URL server
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rssi': wifiData}),
      );

      if (response.statusCode == 200) {
        print("✅ Dữ liệu đã được gửi thành công: ${response.body}");

        // Xử lý dữ liệu trả về từ server
        final responseData = jsonDecode(response.body);

        // Lấy thông tin từ dữ liệu trả về
        String name = responseData['name'];
        List coordinates = responseData['coordinates'];
        int rp = responseData['rp'];

        // Cập nhật vị trí người dùng từ dự đoán của model
        setState(() {
          userPositionCoordinates = LatLng(coordinates[1], coordinates[0]); // Tọa độ từ dữ liệu trả về
          // Cập nhật lại marker người dùng với tọa độ mới
          selectedMarkerRP = rp.toString();
            print("Updated User Position: $userPositionCoordinates"); 
        });
print("User Position: $userPositionCoordinates");
        // Di chuyển bản đồ đến vị trí người dùng
        poiSelectionScreen.mapController.move(userPositionCoordinates, 18);
      } else {
        print("❌ Gửi dữ liệu thất bại: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Lỗi khi quét và gửi dữ liệu Wi-Fi: $e");
    }
  }
Future<void> startWifiTracking() async {
  // Bắt đầu quét Wi-Fi mỗi 5 giây
  wifiScanTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
    // Quét Wi-Fi và gửi dữ liệu
    await scanAndSendWiFiData();
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
Future<void> sendWiFiDataToServer() async {
  final url = Uri.parse('http://192.168.0.100:8765/predict'); // URL server Node.js

  try {
    // Quét các mạng Wi-Fi xung quanh
    var wifiNetworks = await WifiScanner.scanWiFi();
    
    // Kiểm tra xem có mạng Wi-Fi nào được quét không
    if (wifiNetworks.isEmpty) {
      print("❌ Không tìm thấy mạng Wi-Fi");
      return; // Nếu không có mạng, dừng hàm
    }

    // Danh sách các địa chỉ MAC (số lượng MAC cố định)
    List<String> macAddresses = [
      "88:dc:97:12:62:cf", "8e:dc:97:12:65:63", "8e:dc:97:12:65:21", "8e:dc:97:12:65:64", "8e:dc:97:12:65:2b",
            "88:dc:97:12:64:c4", "88:dc:97:12:62:c6", "8e:dc:97:12:62:cf", "b4:5d:50:d7:e9:51", "b4:5d:50:d7:e9:50",
            "88:dc:97:12:62:c7", "8e:dc:97:12:65:22", "88:dc:97:12:65:57", "88:dc:97:12:64:82", "88:dc:97:12:64:83",
            "8e:dc:97:12:62:c7", "8e:dc:97:12:62:c6", "8e:dc:97:12:64:82", "8e:dc:97:12:64:83", "88:dc:97:12:65:58",
            "88:dc:97:12:65:2b", "88:dc:97:12:65:2a", "8e:dc:97:12:64:c4", "88:dc:97:12:62:d0", "b4:5d:50:d7:e9:40",
            "8e:dc:97:12:65:2a", "8e:dc:97:12:62:d0", "88:dc:97:12:65:22", "88:dc:97:12:65:21", "8e:dc:97:12:65:58",
            "8e:dc:97:12:65:57", "b4:5d:50:d7:e9:41", "88:dc:97:12:65:64", "88:dc:97:12:65:63", "88:dc:97:12:62:cc",
            "8e:dc:97:12:62:cc", "88:dc:97:12:65:54", "8e:dc:97:12:65:54", "88:dc:97:12:65:55", "8e:dc:97:12:65:55",
            "88:dc:97:12:62:ff", "8e:dc:97:12:62:ff", "68:ff:7b:d4:f1:cf", "88:dc:97:12:64:c5", "8e:dc:97:12:64:c5",
            "8e:dc:97:12:62:cd", "88:dc:97:12:62:cd", "54:af:97:6b:ba:ce", "94:b4:0f:e3:1d:40", "94:b4:0f:e3:1d:41",
            "40:e3:d6:cd:2d:21", "40:e3:d6:cd:2d:20", "94:b4:0f:e3:1d:51", "68:ff:7b:d4:f1:ce", "88:dc:97:12:63:00",
            "40:e3:d6:cd:2d:31", "40:e3:d6:cd:2d:30", "8e:dc:97:12:63:00", "88:dc:97:12:64:4c", "8e:dc:97:12:5f:c9",
            "18:64:72:55:12:90", "18:64:72:55:12:91", "94:b4:0f:e2:d0:b0", "8e:dc:97:12:64:4c", "94:b4:0f:e3:05:51",
            "94:b4:0f:e3:1d:50", "94:b4:0f:e3:05:40", "18:64:72:55:12:81", "8e:dc:97:12:5f:cc", "18:64:72:55:12:80",
            "94:b4:0f:e2:97:71", "94:b4:0f:e2:97:70"
    ];

    // Lấy số lượng MAC cần quét (số lượng RSSI bạn cần)
    int requiredCount = macAddresses.length;

    // Nếu số mạng Wi-Fi quét được ít hơn số lượng MAC yêu cầu, sử dụng -100 cho những vị trí còn thiếu
    List<int> wifiData = [];
wifiData.clear();
    for (int i = 0; i < requiredCount; i++) {
      if (i < wifiNetworks.length) {
        wifiData.add(wifiNetworks[i].level); // Lấy giá trị RSSI của mỗi mạng Wi-Fi
      } else {
        wifiData.add(-100); // Nếu không đủ mạng, gán -100
      }
    }

    // In ra mảng wifiData để kiểm tra các giá trị RSSI quét được
    print("Quét được dữ liệu RSSI: $wifiData");

    // Định dạng dữ liệu RSSI theo yêu cầu của bạn
    Map<String, dynamic> dataToSend = {
      'rssi': wifiData,  // Mảng các giá trị RSSI
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
        userPositionCoordinates = LatLng(coordinates[1], coordinates[0]); // Tọa độ từ dữ liệu trả về
        selectedMarkerRP = rp.toString(); // Cập nhật lại marker người dùng với tọa độ mới
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




Container _categoriesMethod() {
  return Container(
    height: 50, // Đặt chiều cao cho container
    child: SingleChildScrollView(  // Đảm bảo có thể cuộn ngang
      scrollDirection: Axis.horizontal,  // Cuộn theo hướng ngang
      child: Row(
        children: List.generate(categories.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Xử lý khi bấm vào category
              },
              icon: Icon(
                categories[index].icons.icon,  // Lấy icon từ category
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
                    setState(() async {
                      
                      wifiList =
                    await WifiScanner.scanWiFi();
                    if(kDebugMode){
                      for(var wifi in wifiList) {
                        print("SSID: ${wifi.ssid}, RSSI: ${wifi.level}");
                      }
                    }
                    await sendWiFiDataToServer();
                    });

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
  heroTag: "wifi_tracking_button",
  onPressed: () {
    startWifiTracking();
  },
  backgroundColor: Colors.blue,
  child: Icon(Icons.wifi, color: Colors.white),
),
FloatingActionButton(
  heroTag: "stop_tracking_button",
  onPressed: () {
    stopWifiTracking();
  },
  backgroundColor: Colors.red,
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
            MaterialPageRoute(builder: (context) => POISelectionScreenPage(userPositionCoordinates: userPositionCoordinates)),
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
  final LatLng userPositionCoordinates;  // Accept the user position coordinates

  POISelectionScreenPage({required this.userPositionCoordinates,context});  // Constructor

  @override
  _POISelectionScreenPageState createState() => _POISelectionScreenPageState();
}
class _POISelectionScreenPageState extends State<POISelectionScreenPage> {
  late POISelectionScreen poiSelectionScreen;

  @override
  void initState() {
    super.initState();
    poiSelectionScreen = POISelectionScreen(userPositionCoordinates: widget.userPositionCoordinates,context: context);
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
              setState(() {});  // Notify parent to update the state
            }),
          ),
        ],
      ),
    );
  }
}