import 'package:flutter/material.dart';
import 'package:flutter_application_1/Location.dart';
import 'package:flutter_application_1/POISelectionScreen.dart';
import 'package:flutter_application_1/information.dart';
import 'package:flutter_application_1/account.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:flutter_application_1/ultils/wifi_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_application_1/models/category_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentPageIndex = 0;
  late POISelectionScreen poiSelectionScreen;
  LatLng userPositionCoordinates = LatLng(11.95722012378790, 108.44507513707570);
  Timer? wifiScanTimer;
  List<Map<String, dynamic>> posts = [];
  List<CategoryModel> categories = [];

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
    getCategories();
  }

  void getCategories() {
    categories = CategoryModel.getCategories();
  }

  Future<void> startWifiTracking() async {
    wifiScanTimer = Timer.periodic(Duration(seconds: 15), (timer) async {
      await sendWiFiDataToServer();
      print("✅ Đã quét Wi-Fi và gửi dữ liệu đến server");
    });
  }

  Future<void> stopWifiTracking() async {
    if (wifiScanTimer != null && wifiScanTimer!.isActive) {
      wifiScanTimer?.cancel();
      print("❌ Dừng quét Wi-Fi");
    }
  }

  Future<void> sendWiFiDataToServer() async {
    final url = Uri.parse('http://192.168.1.11/predict');
    try {
      var wifiNetworks = await WifiScanner.scanWiFi();
      if (wifiNetworks.isEmpty) {
        print("❌ Không tìm thấy mạng Wi-Fi");
        return;
      }

      List<String> macAddresses = [
        "88:dc:97:12:62:cf", "8e:dc:97:12:65:63", "8e:dc:97:12:65:21",
        "8e:dc:97:12:65:64", "8e:dc:97:12:65:2b", "88:dc:97:12:64:c4",
        "88:dc:97:12:62:c6", "8e:dc:97:12:62:cf", "b4:5d:50:d7:e9:51",
        "b4:5d:50:d7:e9:50", "88:dc:97:12:62:c7", "8e:dc:97:12:65:22",
        "88:dc:97:12:65:57", "88:dc:97:12:64:82", "88:dc:97:12:64:83",
        "8e:dc:97:12:62:c7", "8e:dc:97:12:62:c6", "8e:dc:97:12:64:82",
        "8e:dc:97:12:64:83", "88:dc:97:12:65:58", "88:dc:97:12:65:2b",
        "88:dc:97:12:65:2a", "8e:dc:97:12:64:c4", "88:dc:97:12:62:d0",
        "b4:5d:50:d7:e9:40", "8e:dc:97:12:65:2a", "8e:dc:97:12:62:d0",
        "88:dc:97:12:65:22", "88:dc:97:12:65:21", "8e:dc:97:12:65:58",
        "8e:dc:97:12:65:57", "b4:5d:50:d7:e9:41", "88:dc:97:12:65:64",
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
    final Map<String, String> folderMap = {
      "TV3,4": "tv3_4",
      "Cửa ra vào": "cua_ra_vao",
      "Hội trường thư viện": "hoi_truong_thu_vien",
      "Khu vực tự học": "khu_vuc_tu_hoc",
      "Căn tin": "can_tin",
      "Khu vực đọc": "khu_vuc_doc",
      "Cầu thang tầng 2": "cau_thang_tang_2",
      "Bàn thủ thư": "ban_thu_thu",
      "Phòng tạp chí": "phong_tap_chi",
    };

    posts = [
      {
        'caption': 'Phòng máy tính TV3 và TV4 với hệ thống trang thiết bị hiện đại...',
        'folderName': 'tv3_4',
      },
      {
        'caption': 'Cửa ra vào thư viện gồm 2 cửa là cửa chính ở trước thư viện...',
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
      {
        'caption': 'Khu vực đọc với không gian yên tĩnh...',
        'folderName': 'khu_vuc_doc',
      },
      {
        'caption': 'Lối di chuyển lên tầng 2 của thư viện...',
        'folderName': 'cau_thang_tang_2',
      },
      {
        'caption': 'Bàn thủ thư là nơi làm việc trung tâm của cán bộ thư viện...',
        'folderName': 'ban_thu_thu',
      },
      {
        'caption': 'Phòng tạp chí lưu trữ nhiều loại tạp chí và sách đa dạng...',
        'folderName': 'phong_tap_chi',
      },
    ];
  }

  Future<List<String>> _getImagesFromFolder(String folderName) async {
    try {
      final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
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
      backgroundColor: Color(0xffFFEBCD),
      bottomNavigationBar: _bottomNavBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _searchField(),
              _introductionSection(),
              _newsSection(),
              _mapSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      margin: EdgeInsets.only(top: 20, left: 20, right: 20),
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
                sourcePage: 'DashboardScreen',
              ),
            ),
          );
        },
        child: AbsorbPointer(
          child: TextFormField(
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '   Tìm kiếm địa điểm ...',
              hintStyle: GoogleFonts.openSans(color: Colors.grey[700], fontSize: 18),
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

  Widget _introductionSection() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giới thiệu về Thư viện DLU',
            style: GoogleFonts.openSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Thư viện Đại học Đà Lạt (DLU) là trung tâm tri thức với không gian hiện đại, cung cấp hàng nghìn tài liệu học tập, khu vực tự học yên tĩnh, và các tiện ích như căn tin, phòng máy tính TV3, TV4. Đây là nơi lý tưởng để sinh viên và giảng viên học tập, nghiên cứu và trao đổi kiến thức.',
            style: GoogleFonts.openSans(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _newsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tin tức',
            style: GoogleFonts.openSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          ...posts.map((post) => _buildPostCard(
                caption: post['caption']!,
                folderName: post['folderName']!,
              )),
        ],
      ),
    );
  }

  Widget _buildPostCard({required String caption, required String folderName}) {
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
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage('../assets/images/LibDLU.jpg'),
              ),
              title: Text(
                'Thư viện DLU',
                style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0),
              child: Text(
                caption.length > 100 ? '${caption.substring(0, 100)}...' : caption,
                style: GoogleFonts.openSans(fontSize: 14),
              ),
            ),
            if (folderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                child: FutureBuilder<List<String>>(
                  future: _getImagesFromFolder(folderName),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("Không có hình ảnh"));
                    } else {
                      final images = snapshot.data!;
                      return _buildImageCollage(images);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCollage(List<String> images) {
    final double collageWidth = MediaQuery.of(context).size.width - 32;
    const double collageHeight = 150;
    const double gap = 2.0;

    Widget buildImage(String imagePath, {required double width, required double height}) {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey,
            child: const Center(child: Icon(Icons.error, color: Colors.white)),
          );
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: collageWidth,
        height: collageHeight,
        color: Colors.white,
        child: images.length == 1
            ? buildImage(images[0], width: collageWidth, height: collageHeight)
            : Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  buildImage(
                    images[0],
                    width: (collageWidth - gap) / 2,
                    height: collageHeight,
                  ),
                  SizedBox(width: gap),
                  buildImage(
                    images[1],
                    width: (collageWidth - gap) / 2,
                    height: collageHeight,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _mapSection() {
    return Container(
      margin: EdgeInsets.all(20),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bản đồ',
            style: GoogleFonts.openSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: poiSelectionScreen.buildMapSection(context, () {
              setState(() {});
            }),
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
              MaterialPageRoute(
                builder: (context) => InformationPage(
                  poiSelectionScreen: poiSelectionScreen,
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