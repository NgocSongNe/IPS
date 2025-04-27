import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_application_1/Location.dart';
import 'package:flutter_application_1/dashboard.dart';
import 'package:flutter_application_1/information.dart';
import 'package:flutter_application_1/models/category_model.dart';
import 'package:flutter_application_1/models/map_model.dart';
import 'package:flutter_application_1/POISelectionScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:flutter_application_1/ultils/wifi_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_application_1/ultils/permission.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/widgets/categories_widget.dart';
import 'package:flutter_application_1/widgets/search_field_widget.dart';
import 'package:flutter_application_1/widgets/category_button_widget.dart';
import 'package:flutter_application_1/services/wifi_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  TextEditingController searchPlaceController = TextEditingController();
  int currentPageIndex = 1;
  bool showLabel = true;
  List<CategoryModel> categories = [];
  List<MapModel> maps = [];
  bool _isDialogDismissed = false;
  File? profileImage;

  late POISelectionScreen poiSelectionScreen;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  LatLng userPositionCoordinates = LatLng(11.95722012378790, 108.44507513707570);
  String? selectedMarkerRP;

  Timer? wifiScanTimer;
  WifiService wifiService = WifiService();
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    poiSelectionScreen = POISelectionScreen(
      userPositionCoordinates: userPositionCoordinates,
      selectedCategory: selectedCategory,
      context: context,
      startWifiTracking: startWifiTracking,
      stopWifiTracking: stopWifiTracking,
    );
    getCategories();
    getMaps();
    requestPermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showGuideDialog());

    // Khởi tạo animation cho hiệu ứng fade-in
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    poiSelectionScreen.mapController.move(userPositionCoordinates, 30);
  }

  Future<void> startWifiTracking() async {
    await wifiService.startWifiTracking(updatePosition);
  }

  void stopWifiTracking() async {
    await wifiService.stopWifiTracking(wifiScanTimer);
  }

  void _showGuideDialog() async {
    final prefs = await SharedPreferences.getInstance();
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
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Vuốt để di chuyển",
                  style: GoogleFonts.openSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.chevron_left, size: 30, color: Colors.teal),
                    Icon(Icons.swipe, size: 50, color: Colors.teal),
                    Icon(Icons.chevron_right, size: 30, color: Colors.teal),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await prefs.setBool('hasShownSwipeGuide', true);
                    Future.delayed(Duration(milliseconds: 300), () {
                      setState(() {
                        _isDialogDismissed = true;
                      });
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  child: Text(
                    "OK",
                    style: GoogleFonts.openSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
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
      backgroundColor: Colors.white,
      bottomNavigationBar: _bottomNavBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal.shade50,
              Colors.blue.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: 20),
                  _buildHeader(),
                  SizedBox(height: 20),
                  _searchField(),
                  SizedBox(height: 15),
                  _categoriesMethod(),
                  SizedBox(height: 15),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: poiSelectionScreen.buildMapSection(context, () {
                              setState(() {});
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: Column(
                  children: [
                    _buildFloatingButton(
                      icon: Icons.my_location,
                      gradient: LinearGradient(
                        colors: [Colors.yellow.shade400, Colors.yellow.shade600],
                      ),
                      onPressed: () async {
                        wifiList = await WifiScanner.scanWiFi();
                        if (kDebugMode) {
                          for (var wifi in wifiList) {
                            print("SSID: ${wifi.ssid}, RSSI: ${wifi.level}");
                          }
                        }
                        startWifiTracking();
                      },
                      heroTag: "location_button",
                    ),
                    SizedBox(height: 15),
                    _buildFloatingButton(
                      icon: Icons.stop,
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      onPressed: () {
                        stopWifiTracking();
                      },
                      heroTag: "stop_wifi_button",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Bản đồ thư viện',
            style: GoogleFonts.openSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          Icon(
            Icons.map,
            color: Colors.teal.shade600,
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          // gradient: LinearGradient(
          //   colors: [Colors.teal.shade200, Colors.blue.shade200],
          //   begin: Alignment.centerLeft,
          //   end: Alignment.centerRight,
          // ),
          borderRadius: BorderRadius.circular(30),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.15),
          //     blurRadius: 15,
          //     offset: Offset(0, 5),
          //   ),
          // ],
        ),
        child: SearchFieldWidget(
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
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onPressed,
    required String heroTag,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _categoryButton(String title, IconData icon) {
    return CategoryButtonWidget(
      title: title,
      icon: icon,
      onPressed: () {
        setState(() {
          selectedCategory = title;
          poiSelectionScreen.selectedCategory = title;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => POISelectionScreenPage(
              userPositionCoordinates: userPositionCoordinates,
              selectedCategory: selectedCategory,
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
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => InformationPage()),
            );
          }
        }
      },
      indicatorColor: Colors.teal.shade200,
      selectedIndex: currentPageIndex,
      backgroundColor: Colors.white,
      elevation: 10,
      destinations: const <Widget>[
        NavigationDestination(
          selectedIcon: Icon(Icons.home, color: Colors.teal),
          icon: Icon(Icons.home_outlined, color: Colors.grey),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.map, color: Colors.teal),
          icon: Badge(child: Icon(Icons.map_outlined, color: Colors.grey)),
          label: 'Bản đồ',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.info, color: Colors.teal),
          icon: Badge(child: Icon(Icons.info_outline, color: Colors.grey)),
          label: 'Thông tin',
        ),
      ],
    );
  }
}

class POISelectionScreenPage extends StatefulWidget {
  final LatLng userPositionCoordinates;
  final Function startWifiTracking;
  final Function stopWifiTracking;
  String? selectedCategory;

  POISelectionScreenPage({
    required this.userPositionCoordinates,
    this.selectedCategory,
    context,
    required this.startWifiTracking,
    required this.stopWifiTracking,
  });

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
      stopWifiTracking: widget.stopWifiTracking,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chọn Địa Điểm",
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          if (poiSelectionScreen.startPOI != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Điểm bắt đầu: RP ${poiSelectionScreen.startPOI}",
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  color: Colors.teal.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (poiSelectionScreen.endPOI != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Điểm kết thúc: RP ${poiSelectionScreen.endPOI}",
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  color: Colors.teal.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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