import 'package:flutter/material.dart';
import 'package:flutter_application_1/Location.dart';
import 'package:flutter_application_1/POISelectionScreen.dart';
import 'package:flutter_application_1/home.dart';
import 'package:flutter_application_1/information.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/widgets/post_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:flutter_application_1/ultils/wifi_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

  
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
 
  int currentPageIndex = 0;
  late POISelectionScreen poiSelectionScreen;
  LatLng userPositionCoordinates =
      LatLng(11.95722012378790, 108.44507513707570);
  Timer? wifiScanTimer;
  List<Map<String, dynamic>> posts = [];
  List<Map<String, dynamic>> suggestedPOIs = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String baseurl= dotenv.env['API_URL'] ?? '';

  final List<String> carouselImages = [
    '../assets/new_year_banner.jpg',
    'assets/images/khu_vuc_doc/image1.jpg',
    'assets/images/khu_vuc_tu_hoc/image1.jpg',
    'assets/images/hoi_truong_thu_vien/image2.jpg',
    'assets/images/khu_vuc_tu_hoc/image2.jpg',
  ];

  @override
   void initState() {
    super.initState();
    poiSelectionScreen = POISelectionScreen(
      userPositionCoordinates: userPositionCoordinates,
      selectedCategory: null,
      context: context,
      startWifiTracking: startWifiTracking,
      stopWifiTracking: stopWifiTracking,
    );
    _loadPosts();
    _loadSuggestedPOIs();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    wifiScanTimer?.cancel();
    super.dispose();
  }

  Future<void> startWifiTracking() async {
    wifiScanTimer = Timer.periodic(Duration(seconds: 15), (timer) async {
      await sendWiFiDataToServer();
      print("✅ Đã quét Wi-Fi và gửi dữ liệu đến server");

      // Chuyển hướng đến HomePage sau khi bắt đầu quét Wi-Fi
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
  }

  Future<void> stopWifiTracking() async {
    if (wifiScanTimer != null && wifiScanTimer!.isActive) {
      wifiScanTimer?.cancel();
      print("❌ Dừng quét Wi-Fi");
    }
  }

  Future<void> sendWiFiDataToServer() async {
    final url = Uri.parse('$baseurl/predict');
    try {
      var wifiNetworks = await WifiScanner.scanWiFi();
      if (wifiNetworks.isEmpty) {
        print("❌ Không tìm thấy mạng Wi-Fi");
        return;
      }

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

      Map<String, int> macToRssi = {};
      for (var wifi in wifiNetworks) {
        if (macAddresses.contains(wifi.bssid)) {
          macToRssi[wifi.bssid] = wifi.level;
        }
      }

      List<int> wifiData = [];
      for (var mac in macAddresses) {
        wifiData.add(macToRssi[mac] ?? -100);
      }

      Map<String, dynamic> dataToSend = {'rssi': wifiData};
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dataToSend),
      );

      if (response.statusCode == 200) {
        print("✅ Dữ liệu đã được gửi thành công: ${response.body}");
        var responseData = jsonDecode(response.body);
        String name = responseData['name'];
        List coordinates = responseData['coordinates'];
        int rp = responseData['rp'];

        setState(() {
          userPositionCoordinates = LatLng(coordinates[1], coordinates[0]);
          poiSelectionScreen.selectedMarkerRP = rp.toString();
        });

        poiSelectionScreen.mapController.move(userPositionCoordinates, 30);
      } else {
        print("❌ Gửi dữ liệu thất bại: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Lỗi khi quét và gửi dữ liệu Wi-Fi: $e");
    }
  }

  Future<void> _loadPosts() async {
    posts = [
      {
        'caption':
            'Phòng máy tính TV3 và TV4 với hệ thống trang thiết bị hiện đại...',
        'folderName': 'tv3_4',
      },
      {
        'caption':
            'Cửa ra vào thư viện gồm 2 cửa là cửa chính ở trước thư viện...',
        'folderName': 'cua_ra_vao',
      },
      {
        'caption': 'Hội trường thư viện có không gian rộng lớn, hiện đại...',
        'folderName': 'hoi_truong_thu_vien',
      },
      {
        'caption': 'Khu vực tự học với đầy đủ bàn ghế, ổ cắm điện...',
        'folderName': 'khu_vuc_tu_hoc',
      },
      {
        'caption': 'Căn tin hiện đại, đa dạng về các loại mặt hàng...',
        'folderName': 'can_tin',
      },
    ];
  }

  Future<void> _loadSuggestedPOIs() async {
    await poiSelectionScreen.loadGeoJson();
    await poiSelectionScreen.loadPOIData();
    setState(() {
      suggestedPOIs = poiSelectionScreen.poiList
          .where((poi) =>
              !poi['rp'].startsWith('wp_') &&
              poi['rp'] != 'userPosition' &&
              poi['name'] != 'Cầu thang')
          .take(5)
          .toList();
    });
  }

  Future<List<String>> _getImagesFromFolder(String folderName) async {
    try {
      final manifestContent =
          await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final imagePaths = manifestMap.keys
          .where((String key) => key.startsWith('assets/images/$folderName/'))
          .toList();
      return imagePaths;
    } catch (e) {
      print("Error loading images for folder $folderName: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _bottomNavBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  SizedBox(height: 20),
                  _carouselSection(),
                  SizedBox(height: 20),
                  _newsSection(),
                  _suggestedPOIsSection(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.teal.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Chào mừng đến với',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              Text(
                'Thư viện DLU',
                style: GoogleFonts.openSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Hôm nay: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              // Chuyển hướng đến HomePage khi nhấn nút tìm kiếm
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Icon(
                Icons.search,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carouselSection() {
    return FlutterCarousel(
      options: CarouselOptions(
        height: 200,
        autoPlay: true,
        autoPlayInterval: Duration(seconds: 3),
        enlargeCenterPage: true,
        viewportFraction: 0.9,
        aspectRatio: 2.0,
        showIndicator: true,
        slideIndicator: CircularSlideIndicator(),
      ),
      items: carouselImages.map((imagePath) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey,
                      child:
                          Center(child: Icon(Icons.error, color: Colors.white)),
                    );
                  },
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _suggestedPOIsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Được gợi ý gần đây',
              style: GoogleFonts.openSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.teal.shade800),
              onPressed: () {
                // Chuyển hướng đến HomePage khi nhấn mũi tên
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
            ),
          ],
        ),
        ...suggestedPOIs.map((poi) => _buildSuggestedPOICard(poi)),
      ],
    );
  }

  Widget _buildSuggestedPOICard(Map<String, dynamic> poi) {
    return GestureDetector(
      onTap: () {
        // Chọn điểm này trên bản đồ
        poiSelectionScreen.onPOITap(poi['rp'], context, () {});
        // Chuyển hướng ngay lập tức đến HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.teal.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.teal.shade600,
                size: 30,
              ),
              ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poi['name'] ?? 'Unknown',
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    poi['description'] ?? 'Không có mô tả',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                  ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.teal.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _newsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tin tức',
              style: GoogleFonts.openSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.teal.shade800),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InformationPage(),
                  ),
                );
              },
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: posts
                .map((post) => _buildNewsCard(
                      caption: post['caption']!,
                      folderName: post['folderName']!,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsCard({required String caption, required String folderName}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              caption: caption,
              folderName: folderName,
              customImagePath: null,
            ),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: EdgeInsets.only(right: 16),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<List<String>>(
                future: _getImagesFromFolder(folderName),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return Container(
                      height: 120,
                      color: Colors.grey,
                      child: Center(child: Text("Không có hình ảnh")),
                    );
                  } else {
                    final images = snapshot.data!;
                    return ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(10)),
                      child: Image.asset(
                        images[0],
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: Colors.grey,
                            child: Center(
                                child: Icon(Icons.error, color: Colors.white)),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  caption.length > 50
                      ? '${caption.substring(0, 50)}...'
                      : caption,
                  style: GoogleFonts.openSans(
                      fontSize: 14, color: Colors.grey.shade800),
                ),
              ),
            ],
          ),
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
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
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