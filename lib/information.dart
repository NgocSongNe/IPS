import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/dashboard.dart';
import 'package:flutter_application_1/home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/models/category_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/POISelectionScreen.dart'; // Import POISelectionScreen
import 'Location.dart';
import 'widgets/post_card.dart'; // Import PostCard widget

class InformationPage extends StatefulWidget {
  final String? poiName; // Tham số để nhận tên địa điểm từ trang Home
  final POISelectionScreen? poiSelectionScreen; // Nhận poiSelectionScreen từ HomePage

  const InformationPage({super.key, this.poiName, this.poiSelectionScreen});

  @override
  State<InformationPage> createState() => _InformationPageState();
}
class _InformationPageState extends State<InformationPage> {
  int currentPageIndex = 2;
  List<CategoryModel> categories = [];

  // Khai báo biến postCards sử dụng final
  final List<Widget> postCards = [];

  // Danh sách các thư mục chứa hình ảnh cho từng mục
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

  // Lưu trữ thông tin bài đăng để điều hướng
  final Map<String, Map<String, String>> postMap = {};

  @override
  void initState() {
    super.initState();
    getCategories();

    // Khởi tạo các bài đăng và ánh xạ với folderName
    postCards.addAll([
      PostCard(
        caption:
            'Phòng máy tính TV3 và TV4 với hệ thống trang thiết bị hiện đại, phòng học được trang bị các bộ máy tính được kết nối Internet chất lượng cao. Phòng học đáp ứng được các nhu cầu về học tập và làm việc một cách ổn định và mượt mà.',
        folderName: 'tv3_4',
      ),
      PostCard(
        caption:
            'Cửa ra vào thư viện gồm 2 cửa là cửa chính ở trước thư viện và cửa sau dẫn ra bãi đỗ xe cổng sau, thuận tiện cho việc di chuyển và đảm bảo an ninh.',
        folderName: 'cua_ra_vao',
      ),
      PostCard(
        caption:
            'Hội trường thư viện có không gian rộng lớn, hiện đại, số lượng ghế ngồi rộng lớn với khoảng 300 chỗ. Phòng phù hợp cho các buổi hội thảo, các cuộc họp và sự kiện quan trọng.',
        folderName: 'hoi_truong_thu_vien',
      ),
      PostCard(
        caption:
            'Khu vực tự học với đầy đủ bàn ghế, ổ cắm điện và không gian yên tĩnh. Các khu vực tự học học được bố trí ở nhiều nơi trong thư viện, là nơi lý tưởng cho việc học tập và nghiên cứu.',
        folderName: 'khu_vuc_tu_hoc',
      ),
      PostCard(
        caption:
            'Căn tin hiện đại, đa dạng về các loại mặt hàng, cung cấp nhiều loại đồ ăn và thức uống. Khu vực có thể đáp ứng các nhu cầu ăn uống, mua sắm các vật dụng hỗ trợ cho cả sinh viên và cán bộ giảng viên.',
        folderName: 'can_tin',
      ),
      PostCard(
        caption:
            'Khu vực đọc với không gian yên tĩnh, cung cấp nhiều loại sách và tài liệu học tập được sắp xếp gọn gàng ở các kệ sách trong khu vực. Hỗ trợ thuận tiện cho việc tìm kiếm tài liệu và học tập.',
        folderName: 'khu_vuc_doc',
      ),
      PostCard(
        caption:
            'Lối di chuyển lên tầng 2 của thư viện. Thư viện bố trí 2 cầu thang di chuyển ở hai bên trái phải, thuận tiện cho việc di chuyển giữa các tầng.',
        folderName: 'cau_thang_tang_2',
      ),
      PostCard(
        caption:
            'Bàn thủ thư là nơi làm việc trung tâm của cán bộ thư viện. Đây là khu vực hỗ trợ sinh viên và cán bộ giảng viên trong việc tìm kiếm, mượn tài liệu.',
        folderName: 'ban_thu_thu',
      ),
      PostCard(
        caption:
            'Phòng tạp chí lưu trữ nhiều loại tạp chí và sách đa dạng thể loại, phục vụ nhu cầu nghiên cứu và học tập.',
        folderName: 'phong_tap_chi',
      ),
    ]);
  }

  void getCategories() {
    categories = CategoryModel.getCategories();
  }

  // Hàm lấy danh sách hình ảnh từ thư mục
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
      backgroundColor: Color(0xffFFEBCD),
      bottomNavigationBar: _bottomNavBar(),
     
      body: SingleChildScrollView(
        child: Column(
          children: [
            _searchField(),
            SizedBox(height: 20),
            _buildPostCards(),
          ],
        ),
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
          if (widget.poiSelectionScreen == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Không thể mở tìm kiếm: Dữ liệu bản đồ không khả dụng')),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SuggestedPlacesScreen(
                poiSelectionScreen: widget.poiSelectionScreen,
                sourcePage: 'InformationPage', // Truyền sourcePage
              ),
            ),
          );
        },
        child: AbsorbPointer(
          child: TextFormField(
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Tìm kiếm địa điểm ...',
              hintStyle:
                  GoogleFonts.openSans(color: Colors.grey[700], fontSize: 18),
              prefixIcon: Icon(Icons.gps_fixed, size: 25, color: Colors.black),
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

  Widget _buildPostCards() {
    return Column(
      children: postCards,
    );
  }

  NavigationBar _bottomNavBar() {
    return NavigationBar(
      onDestinationSelected: (int index) {
        setState(() {
          currentPageIndex = index;
        });
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      },
      indicatorColor: Colors.amber,
      selectedIndex: currentPageIndex,
      destinations: const <Widget>[
        NavigationDestination(
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Badge(child: Icon(Icons.map)),
          label: 'Map',
        ),
        NavigationDestination(
          icon: Badge(child: Icon(Icons.info_outline)),
          label: 'Thông tin',
        ),
      ],
    );
  }
}
