import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/account.dart';
import 'package:flutter_application_1/home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/models/category_model.dart';
import 'package:image_picker/image_picker.dart';
import 'Location.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  int currentPageIndex = 1;
  List<Widget> postCards = [];
  List<CategoryModel> categories = [];

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

  @override
  void initState() {
    super.initState();
     getCategories();
    // Khởi tạo các bài đăng với caption và hình ảnh từ các thư mục tương ứng
    postCards = [
      _buildPostCard(
        caption:
            'Phòng máy tính TV3 và TV4 với hệ thống trang thiết bị hiện đại, phòng học được trang bị các bộ máy tính được kết nối Internet chất lượng cao. Phòng học đáp ứng được các nhu cầu về học tập và làm việc một cách ổn định và mượt mà.',
        folderName: 'tv3_4',
      ),
      _buildPostCard(
        caption:
            'Cửa ra vào thư viện với thiết kế hiện đại, thuận tiện cho việc di chuyển và đảm bảo an ninh.',
        folderName: 'cua_ra_vao',
      ),
      _buildPostCard(
        caption:
            'Hội trường thư viện là không gian rộng lớn, hiện đại, phù hợp cho các buổi hội thảo và sự kiện quan trọng.',
        folderName: 'hoi_truong_thu_vien',
      ),
      _buildPostCard(
        caption:
            'Khu vực tự học với đầy đủ bàn ghế, ổ cắm điện và không gian yên tĩnh, lý tưởng cho việc học tập và nghiên cứu.',
        folderName: 'khu_vuc_tu_hoc',
      ),
      _buildPostCard(
        caption:
            'Căn tin hiện đại, cung cấp nhiều loại đồ ăn và thức uống, đáp ứng nhu cầu của sinh viên và cán bộ.',
        folderName: 'can_tin',
      ),
      _buildPostCard(
        caption:
            'Khu vực đọc với không gian yên tĩnh, cung cấp nhiều loại sách và tài liệu học tập.',
        folderName: 'khu_vuc_doc',
      ),
      _buildPostCard(
        caption:
            'Cầu thang tầng 2 được thiết kế chắc chắn, thuận tiện cho việc di chuyển giữa các tầng.',
        folderName: 'cau_thang_tang_2',
      ),
      _buildPostCard(
        caption:
            'Bàn thủ thư là nơi làm việc trung tâm của các thủ thư, hỗ trợ sinh viên và cán bộ trong việc tìm kiếm tài liệu.',
        folderName: 'ban_thu_thu',
      ),
      _buildPostCard(
        caption:
            'Phòng tạp chí lưu trữ nhiều loại tạp chí và sách đa dạng thể loại, phục vụ nhu cầu nghiên cứu và học tập.',
        folderName: 'phong_tap_chi',
      ),
    ];
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

  void _showAddPostDialog() {
    final TextEditingController captionController = TextEditingController();
    File? postImage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Thêm bài đăng mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: captionController,
                  decoration: InputDecoration(labelText: 'Nhập caption'),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                postImage == null
                    ? ElevatedButton(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setDialogState(() {
                              postImage = File(pickedFile.path);
                            });
                          }
                        },
                        child: Text('Chọn ảnh'),
                      )
                    : Column(
                        children: [
                          Image.file(postImage!, height: 100),
                          TextButton(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery);
                              if (pickedFile != null) {
                                setDialogState(() {
                                  postImage = File(pickedFile.path);
                                });
                              }
                            },
                            child: Text('Thay đổi ảnh'),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (captionController.text.isNotEmpty || postImage != null) {
                  setState(() {
                    postCards.add(_buildPostCard(
                      caption: captionController.text.isNotEmpty
                          ? captionController.text
                          : 'Không có caption',
                      folderName: '',
                      customImagePath: postImage?.path,
                    ));
                  });
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã thêm bài đăng!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Vui lòng nhập caption hoặc chọn ảnh!')),
                  );
                }
              },
              child: Text('Đăng'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFEBCD),
      bottomNavigationBar: _bottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostDialog,
        backgroundColor: Colors.lightGreen,
        child: Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _searchField(),
            SizedBox(height: 20),
            _categoriesMethod(),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SuggestedPlacesScreen()),
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

Container _categoriesMethod() {
  return Container(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(categories.length, (index) {
          return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
            child: ElevatedButton.icon(
                onPressed: () {},
              icon: categories[index].icons,
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

  Widget _buildPostCards() {
    return Column(
      children: postCards,
    );
  }

  Widget _buildPostCard({
    String caption = 'Mô phỏng nội dung',
    String folderName = '',
    String? customImagePath,
  }) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage('../assets/avt_st.jpg'),
            ),
            title: Text(
              'Tăng Thế Ngọc Song',
              style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('28 tháng 1 lúc 05:00'),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0),
            child: Text(
              caption,
              style: GoogleFonts.openSans(fontSize: 14),
            ),
          ),
          if (customImagePath != null && customImagePath.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: Image.file(
                  File(customImagePath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                  height: 200,
                ),
              ),
            )
          else if (folderName.isNotEmpty)
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
    );
  }

  Widget _buildImageCollage(List<String> images) {
    // Định nghĩa chiều cao và chiều rộng cố định cho toàn bộ khối hình ảnh
    final double collageWidth = MediaQuery.of(context).size.width - 32; // Trừ padding trái/phải (16 + 16)
    const double collageHeight = 200;
    const double gap = 2.0; // Khoảng cách giữa các hình ảnh (đường viền trắng)

    // Hàm tạo widget hình ảnh
    Widget buildImage(String imagePath, {required double width, required double height}) {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover, // Cắt hình ảnh để lấp đầy toàn bộ không gian
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey,
            child: const Center(
              child: Icon(Icons.error, color: Colors.white),
            ),
          );
        },
      );
    }

    // Bọc toàn bộ khối hình ảnh trong ClipRRect để bo tròn viền
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: collageWidth,
        height: collageHeight,
        color: Colors.white, // Màu nền trắng để tạo đường viền trắng giữa các hình ảnh
        // Nếu chỉ có 1 hình ảnh
        child: images.length == 1
            ? buildImage(
                images[0],
                width: collageWidth,
                height: collageHeight,
              )
            // Nếu có 2 hình ảnh
            : images.length == 2
                ? Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      buildImage(
                        images[0],
                        width: (collageWidth - gap) / 2,
                        height: collageHeight,
                      ),
                      SizedBox(width: gap), // Đường viền trắng
                      buildImage(
                        images[1],
                        width: (collageWidth - gap) / 2,
                        height: collageHeight,
                      ),
                    ],
                  )
                // Nếu có 3 hình ảnh
                : images.length == 3
                    ? Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          buildImage(
                            images[0],
                            width: (collageWidth - gap) / 2,
                            height: collageHeight,
                          ),
                          SizedBox(width: gap), // Đường viền trắng
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              buildImage(
                                images[1],
                                width: (collageWidth - gap) / 2,
                                height: (collageHeight - gap) / 2,
                              ),
                              SizedBox(height: gap), // Đường viền trắng
                              buildImage(
                                images[2],
                                width: (collageWidth - gap) / 2,
                                height: (collageHeight - gap) / 2,
                              ),
                            ],
                          ),
                        ],
                      )
                    // Nếu có 4 hình ảnh trở lên
                    : Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              buildImage(
                                images[0],
                                width: (collageWidth - gap) / 2,
                                height: (collageHeight - gap) / 2,
                              ),
                              SizedBox(height: gap), // Đường viền trắng
                              buildImage(
                                images[1],
                                width: (collageWidth - gap) / 2,
                                height: (collageHeight - gap) / 2,
                              ),
                            ],
                          ),
                          SizedBox(width: gap), // Đường viền trắng
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              buildImage(
                                images[2],
                                width: (collageWidth - gap) / 2,
                                height: (collageHeight - gap) / 2,
                              ),
                              SizedBox(height: gap), // Đường viền trắng
                              Stack(
                                children: [
                                  buildImage(
                                    images[3],
                                    width: (collageWidth - gap) / 2,
                                    height: (collageHeight - gap) / 2,
                                  ),
                                  if (images.length > 4)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withOpacity(0.5),
                                        child: Center(
                                          child: Text(
                                            '+${images.length - 4}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
      ),
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
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else if (index == 1) {
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
          icon: Badge(child: Icon(Icons.book_online_outlined)),
          label: 'Thông tin',
        ),
        NavigationDestination(
          icon: Badge(
            child: Icon(Icons.manage_accounts_outlined),
          ),
          label: 'Tài khoản',
        ),
      ],
    );
  }
}
