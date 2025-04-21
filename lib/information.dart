import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Location.dart';
import 'package:flutter_application_1/dashboard.dart';
import 'package:flutter_application_1/home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/models/category_model.dart';
import 'package:flutter_application_1/POISelectionScreen.dart';
import 'widgets/post_card.dart'; // Import PostCard widget

class InformationPage extends StatefulWidget {
  final String? poiName;
  final POISelectionScreen? poiSelectionScreen;

  const InformationPage({super.key, this.poiName, this.poiSelectionScreen});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage>
    with SingleTickerProviderStateMixin {
  int currentPageIndex = 2;
  List<CategoryModel> categories = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> postCards = [];

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

  final Map<String, Map<String, String>> postMap = {};

  @override
  void initState() {
    super.initState();
    getCategories();

    postCards.addAll([
      PostCard(
        caption:
            'Phòng máy tính TV3 và TV4 - với hệ thống trang thiết bị hiện đại, phòng học được trang bị các bộ máy tính được kết nối Internet chất lượng cao. Phòng học đáp ứng được các nhu cầu về học tập và làm việc một cách ổn định và mượt mà.',
        folderName: 'tv3_4',
      ),
      PostCard(
        caption:
            'Cửa ra vào thư viện - gồm 2 cửa là cửa chính ở trước thư viện và cửa sau dẫn ra bãi đỗ xe cổng sau, thuận tiện cho việc di chuyển và đảm bảo an ninh.',
        folderName: 'cua_ra_vao',
      ),
      PostCard(
        caption:
            'Hội trường thư viện - có không gian rộng lớn, hiện đại, số lượng ghế ngồi rộng lớn với khoảng 300 chỗ. Phòng phù hợp cho các buổi hội thảo, các cuộc họp và sự kiện quan trọng.',
        folderName: 'hoi_truong_thu_vien',
      ),
      PostCard(
        caption:
            'Khu vực tự học - với đầy đủ bàn ghế, ổ cắm điện và không gian yên tĩnh. Các khu vực tự học học được bố trí ở nhiều nơi trong thư viện, là nơi lý tưởng cho việc học tập và nghiên cứu.',
        folderName: 'khu_vuc_tu_hoc',
      ),
      PostCard(
        caption:
            'Căn tin - hiện đại, đa dạng về các loại mặt hàng, cung cấp nhiều loại đồ ăn và thức uống. Khu vực có thể đáp ứng các nhu cầu ăn uống, mua sắm các vật dụng hỗ trợ cho cả sinh viên và cán bộ giảng viên.',
        folderName: 'can_tin',
      ),
      PostCard(
        caption:
            'Khu vực đọc - với không gian yên tĩnh, cung cấp nhiều loại sách và tài liệu học tập được sắp xếp gọn gàng ở các kệ sách trong khu vực. Hỗ trợ thuận tiện cho việc tìm kiếm tài liệu và học tập.',
        folderName: 'khu_vuc_doc',
      ),
      PostCard(
        caption:
            'Lối di chuyển lên tầng 2 - của thư viện. Thư viện bố trí 2 cầu thang di chuyển ở hai bên trái phải, thuận tiện cho việc di chuyển giữa các tầng.',
        folderName: 'cau_thang_tang_2',
      ),
      PostCard(
        caption:
            'Bàn thủ thư - là nơi làm việc trung tâm của cán bộ thư viện. Đây là khu vực hỗ trợ sinh viên và cán bộ giảng viên trong việc tìm kiếm, mượn tài liệu.',
        folderName: 'ban_thu_thu',
      ),
      PostCard(
        caption:
            'Phòng tạp chí - lưu trữ nhiều loại tạp chí và sách đa dạng thể loại, phục vụ nhu cầu nghiên cứu và học tập.',
        folderName: 'phong_tap_chi',
      ),
    ]);

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
    super.dispose();
  }

  void getCategories() {
    categories = CategoryModel.getCategories();
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
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    _buildHeader(),
                    SizedBox(height: 20),
                    _buildPostCards(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Thông tin thư viện',
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
          Icons.info_outline,
          color: Colors.teal.shade600,
          size: 30,
        ),
      ],
    );
  }

  Widget _buildPostCards() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: postCards.length,
      itemBuilder: (context, index) {
        return AnimatedOpacity(
          opacity: 1.0,
          duration: Duration(milliseconds: 500 + (index * 100)),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildEnhancedPostCard(postCards[index] as PostCard),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedPostCard(PostCard postCard) {
    String title = postCard.caption.split('-').first.trim();
    String content = postCard.caption.length > 100
        ? '${postCard.caption.substring(0, 100)}...'
        : postCard.caption;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              caption: postCard.caption,
              folderName: postCard.folderName,
              customImagePath: null,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị hình ảnh dưới dạng danh sách ngang (horizontal list)
            FutureBuilder<List<String>>(
              future: _getImagesFromFolder(postCard.folderName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey.shade600,
                        size: 50,
                      ),
                    ),
                  );
                } else {
                  final images = snapshot.data!;
                  return Container(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              images[index],
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 150,
                                  height: 150,
                                  color: Colors.grey.shade300,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey.shade600,
                                      size: 50,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.openSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    content,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Xem thêm',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: Colors.teal.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.teal.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
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