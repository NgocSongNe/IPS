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
import 'package:wifi_scan/wifi_scan.dart';
import 'dart:io';
import 'package:flutter_application_1/ultils/wifi_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_application_1/ultils/permission.dart';
import 'package:flutter_application_1/widgets/categories_widget.dart';
import 'package:flutter_application_1/widgets/search_field_widget.dart';
import 'package:flutter_application_1/widgets/category_button_widget.dart'; 
import 'package:flutter_application_1/services/wifi_service.dart';
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
  File? profileImage;

  late POISelectionScreen poiSelectionScreen;

  LatLng userPositionCoordinates = LatLng(11.95722012378790, 108.44507513707570); // Tọa độ mặc định cho người dùng
  String? selectedMarkerRP;

  Timer? wifiScanTimer;
  WifiService wifiService = WifiService();
  String? selectedCategory;
  @override
  void initState() {
    super.initState();
    poiSelectionScreen = POISelectionScreen(userPositionCoordinates: userPositionCoordinates,selectedCategory: selectedCategory,context: context,startWifiTracking:startWifiTracking,stopWifiTracking:stopWifiTracking); // Initialize POISelectionScreen with user position coordinates
    getCategories();
    getMaps();
    requestPermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showGuideDialog());
  }

  void getCategories() {
    categories = CategoryModel.getCategories();
  }

  void getMaps() {
    maps = MapModel.getMaps();
  }
 void updatePosition(List coordinates, int rp) {
    setState(() {
      userPositionCoordinates = LatLng(coordinates[1], coordinates[0]);
      selectedMarkerRP = rp.toString();
    });

    // Di chuyển bản đồ đến vị trí người dùng
    poiSelectionScreen.mapController.move(userPositionCoordinates, 30);
  }
 Future<void> startWifiTracking() async {
    await wifiService.startWifiTracking(updatePosition); // Truyền callback để cập nhật vị trí người dùng
  }

  // Dừng quét Wi-Fi
  void stopWifiTracking() async {
    await wifiService.stopWifiTracking(wifiScanTimer);
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
                children: const[
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
Widget _categoriesMethod() {
  return CategoriesWidget(
    categories: categories,
    onCategorySelected: (selectedCategory) {
      setState(() {
        this.selectedCategory = selectedCategory;
        poiSelectionScreen.selectedCategory = selectedCategory;
      });
    },
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
              const SizedBox(height: 5),
            
             _categoriesMethod(),
              const SizedBox(height: 10),
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
                    
                      
                      wifiList =
                    await WifiScanner.scanWiFi();
                    if(kDebugMode){
                      for(var wifi in wifiList) {
                        print("SSID: ${wifi.ssid}, RSSI: ${wifi.level}");
                      }
                    }
                    startWifiTracking();
                   

                    String? imagePath;
                    if (imagePath != null) {
                      profileImage = File(imagePath);
                    }
                  },
                  backgroundColor: Colors.yellow,
                  child:const Icon(Icons.my_location, color: Colors.black),
                ),
                const SizedBox(height: 10),
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
  return SearchFieldWidget(
    controller: searchPlaceController,
    onSearch: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SuggestedPlacesScreen(
            poiSelectionScreen: poiSelectionScreen,
            sourcePage: 'HomePage',
          ),
        ),
      );
    },
  );
}




  Widget _categoryButton(String title, IconData icon) {
    return CategoryButtonWidget(
    title: title,
    icon: icon,
    onPressed: () {
      setState(() {
        selectedCategory = title;
        poiSelectionScreen.selectedCategory = title; // Cập nhật selectedCategory trong POISelectionScreen
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => POISelectionScreenPage(
            userPositionCoordinates: userPositionCoordinates,
            selectedCategory: selectedCategory, // Truyền selectedCategory
            startWifiTracking: startWifiTracking,
            stopWifiTracking: stopWifiTracking,
          ),
        ),
      );
    },
  );
  }

  NavigationBar _bottomNavBar() {
    return NavigationBar(
      onDestinationSelected: (int index) {
        if (index != currentPageIndex) {
          setState(() {
            currentPageIndex = index;
          });
          if (index == 2) {
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
      destinations: const [
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
  final LatLng userPositionCoordinates;  // Accept the user position coordinates
  final Function startWifiTracking;
  final Function stopWifiTracking;
String? selectedCategory;
  POISelectionScreenPage({required this.userPositionCoordinates,this.selectedCategory,context,required this.startWifiTracking,required this.stopWifiTracking});  // Constructor

  @override
  _POISelectionScreenPageState createState() => _POISelectionScreenPageState();
}
class _POISelectionScreenPageState extends State<POISelectionScreenPage> {
  late POISelectionScreen poiSelectionScreen;

  @override
  void initState() {
    super.initState();
    poiSelectionScreen = POISelectionScreen(userPositionCoordinates: widget.userPositionCoordinates,selectedCategory: widget.selectedCategory,context: context,startWifiTracking: widget.startWifiTracking,stopWifiTracking: widget.stopWifiTracking); // Initialize POISelectionScreen with user position coordinates
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