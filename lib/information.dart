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
  final String? poiName; // Tham số để nhận tên địa điểm từ trang Home

  const InformationPage({super.key, this.poiName});

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

  // Lưu trữ thông tin bài đăng để điều hướng
  final Map<String, Map<String, String>> postMap = {};

  @override
  void initState() {
    super.initState();
     getCategories();

    // Khởi tạo các bài đăng và ánh xạ với folderName
    postCards = [
      _buildPostCard(
        caption:
            'Phòng máy tính TV3 và TV4 với hệ thống trang thiết bị hiện đại, phòng học được trang bị các bộ máy tính được kết nối Internet chất lượng cao. Phòng học đáp ứng được các nhu cầu về học tập và làm việc một cách ổn định và mượt mà.',
        folderName: 'tv3_4',
      ),
      _buildPostCard(
        caption:
            'Cửa ra vào thư viện gồm 2 cửa là cửa chính ở trước thư viện và cửa sau dẫn ra bãi đỗ xe cổng sau, thuận tiện cho việc di chuyển và đảm bảo an ninh.',
        folderName: 'cua_ra_vao',
      ),
      _buildPostCard(
        caption:
            'Hội trường thư viện có không gian rộng lớn, hiện đại, số lượng ghế ngồi rộng lớn với khoảng 300 chỗ. Phòng phù hợp cho các buổi hội thảo, các cuộc họp và sự kiện quan trọng.',
        folderName: 'hoi_truong_thu_vien',
      ),
      _buildPostCard(
        caption:
            'Khu vực tự học với đầy đủ bàn ghế, ổ cắm điện và không gian yên tĩnh. Các khu vực tự học học được bố trí ở nhiều nơi trong thư viện, là nơi lý tưởng cho việc học tập và nghiên cứu.',
        folderName: 'khu_vuc_tu_hoc',
      ),
      _buildPostCard(
        caption:
            'Căn tin hiện đại, đa dạng về các loại mặt hàng, cung cấp nhiều loại đồ ăn và thức uống. Khu vực có thể đáp ứng các nhu cầu ăn uống, mua sắm các vật dụng hỗ trợ cho cả sinh viên và cán bộ giảng viên.',
        folderName: 'can_tin',
      ),
      _buildPostCard(
        caption:
            'Khu vực đọc với không gian yên tĩnh, cung cấp nhiều loại sách và tài liệu học tập được sắp xếp gọn gàng ở các kệ sách trong khu vực. Hỗ trợ thuận tiện cho việc tìm kiếm tài liệu và học tập.',
        folderName: 'khu_vuc_doc',
      ),
      _buildPostCard(
        caption:
            'Lối di chuyển lên tầng 2 của thư viện. Thư viện bố trí 2 cầu thang di chuyển ở hai bên trái phải, thuận tiện cho việc di chuyển giữa các tầng.',
        folderName: 'cau_thang_tang_2',
      ),
      _buildPostCard(
        caption:
            'Bàn thủ thư là nơi làm việc trung tâm của cán bộ thư viện. Đây là khu vực hỗ trợ sinh viên và cán bộ giảng viên trong việc tìm kiếm, mượn tài liệu.',
        folderName: 'ban_thu_thu',
      ),
      _buildPostCard(
        caption:
            'Phòng tạp chí lưu trữ nhiều loại tạp chí và sách đa dạng thể loại, phục vụ nhu cầu nghiên cứu và học tập.',
        folderName: 'phong_tap_chi',
      ),
    ];

    // Tạo ánh xạ từ folderName đến thông tin bài đăng
    postMap['tv3_4'] = {
      'caption':
          'Phòng máy tính TV3 và TV4 với hệ thống trang thiết bị hiện đại, phòng học được trang bị các bộ máy tính được kết nối Internet chất lượng cao. Phòng học đáp ứng được các nhu cầu về học tập và làm việc một cách ổn định và mượt mà.',
      'folderName': 'tv3_4',
    };
    postMap['cua_ra_vao'] = {
      'caption':
          'Cửa ra vào thư viện gồm 2 cửa là cửa chính ở trước thư viện và cửa sau dẫn ra bãi đỗ xe cổng sau, thuận tiện cho việc di chuyển và đảm bảo an ninh.',
      'folderName': 'cua_ra_vao',
    };
    postMap['hoi_truong_thu_vien'] = {
      'caption':
          'Hội trường thư viện có không gian rộng lớn, hiện đại, số lượng ghế ngồi rộng lớn với khoảng 300 chỗ. Phòng phù hợp cho các buổi hội thảo, các cuộc họp và sự kiện quan trọng.',
      'folderName': 'hoi_truong_thu_vien',
    };
    postMap['khu_vuc_tu_hoc'] = {
      'caption':
          'Khu vực tự học với đầy đủ bàn ghế, ổ cắm điện và không gian yên tĩnh. Các khu vực tự học học được bố trí ở nhiều nơi trong thư viện, là nơi lý tưởng cho việc học tập và nghiên cứu.',
      'folderName': 'khu_vuc_tu_hoc',
    };
    postMap['can_tin'] = {
      'caption':
          'Căn tin hiện đại, đa dạng về các loại mặt hàng, cung cấp nhiều loại đồ ăn và thức uống. Khu vực có thể đáp ứng các nhu cầu ăn uống, mua sắm các vật dụng hỗ trợ cho cả sinh viên và cán bộ giảng viên.',
      'folderName': 'can_tin',
    };
    postMap['khu_vuc_doc'] = {
      'caption':
          'Khu vực đọc với không gian yên tĩnh, cung cấp nhiều loại sách và tài liệu học tập được sắp xếp gọn gàng ở các kệ sách trong khu vực. Hỗ trợ thuận tiện cho việc tìm kiếm tài liệu và học tập.',
      'folderName': 'khu_vuc_doc',
    };
    postMap['cau_thang_tang_2'] = {
      'caption':
          'Lối di chuyển lên tầng 2 của thư viện. Thư viện bố trí 2 cầu thang di chuyển ở hai bên trái phải, thuận tiện cho việc di chuyển giữa các tầng.',
      'folderName': 'cau_thang_tang_2',
    };
    postMap['ban_thu_thu'] = {
      'caption':
          'Bàn thủ thư là nơi làm việc trung tâm của cán bộ thư viện. Đây là khu vực hỗ trợ sinh viên và cán bộ giảng viên trong việc tìm kiếm, mượn tài liệu.',
      'folderName': 'ban_thu_thu',
    };
    postMap['phong_tap_chi'] = {
      'caption':
          'Phòng tạp chí lưu trữ nhiều loại tạp chí và sách đa dạng thể loại, phục vụ nhu cầu nghiên cứu và học tập.',
      'folderName': 'phong_tap_chi',
    };

    // Kiểm tra nếu có poiName, điều hướng đến bài đăng tương ứng
    if (widget.poiName != null) {
      String? folderName;
      // Tìm folderName tương ứng với poiName
      folderMap.forEach((key, value) {
        if (key == widget.poiName) {
          folderName = value;
        }
      });

      if (folderName != null && postMap.containsKey(folderName)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailPage(
                caption: postMap[folderName]!['caption']!,
                folderName: postMap[folderName]!['folderName']!,
                customImagePath: null,
              ),
            ),
          );
        });
      }
    }
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              caption: caption,
              folderName: folderName,
              customImagePath: customImagePath,
            ),
          ),
        );
      },
      child: Card(
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
      ),
    );
  }

  Widget _buildImageCollage(List<String> images) {
    final double collageWidth = MediaQuery.of(context).size.width - 32;
    const double collageHeight = 200;
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
        color: Colors.white,
        child: images.length == 1
            ? buildImage(
                images[0],
                width: collageWidth,
                height: collageHeight,
              )
            : images.length == 2
                ? Row(
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
                  )
                : images.length == 3
                    ? Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          buildImage(
                            images[0],
                            width: (collageWidth - gap) / 2,
                            height: collageHeight,
                          ),
                          SizedBox(width: gap),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              buildImage(
                                images[1],
                                width: (collageWidth - gap) / 2,
                                height: (collageHeight - gap) / 2,
                              ),
                              SizedBox(height: gap),
                              buildImage(
                                images[2],
                                width: (collageWidth - gap) / 2,
                                height: (collageHeight - gap) / 2,
                              ),
                            ],
                          ),
                        ],
                      )
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
                              SizedBox(height: gap),
                              buildImage(
                                images[1],
                                width: (collageWidth - gap) / 2,
                                height: (collageHeight - gap) / 2,
                              ),
                            ],
                          ),
                          SizedBox(width: gap),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              buildImage(
                                images[2],
                                width: (collageWidth - gap) / 2,
                                height: (collageHeight - gap) / 2,
                              ),
                              SizedBox(height: gap),
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

class PostDetailPage extends StatelessWidget {
  final String caption;
  final String folderName;
  final String? customImagePath;

  const PostDetailPage({
    Key? key,
    required this.caption,
    required this.folderName,
    this.customImagePath,
  }) : super(key: key);

  Future<List<String>> _getImagesFromFolder(BuildContext context, String folderName) async {
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
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 60.0),
              child: SingleChildScrollView(
                child: Card(
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
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0),
                        child: Text(
                          caption,
                          style: GoogleFonts.openSans(fontSize: 14),
                        ),
                      ),
                      if (customImagePath != null && customImagePath!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImagePage(
                                    images: [customImagePath!],
                                    initialIndex: 0,
                                    isAsset: false,
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                              child: Image.file(
                                File(customImagePath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                              ),
                            ),
                          ),
                        )
                      else if (folderName.isNotEmpty)
                        FutureBuilder<List<String>>(
                          future: _getImagesFromFolder(context, folderName),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(child: Text("Không có hình ảnh"));
                            } else {
                              final images = snapshot.data!;
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: images.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FullScreenImagePage(
                                              images: images,
                                              initialIndex: index,
                                              isAsset: true,
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                                        child: Image.asset(
                                          images[index],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 200,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final List<String> images;
  final int initialIndex;
  final bool isAsset;

  const FullScreenImagePage({
    Key? key,
    required this.images,
    required this.initialIndex,
    required this.isAsset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return Center(
                  child: isAsset
                      ? Image.asset(
                          images[index],
                          fit: BoxFit.contain,
                        )
                      : Image.file(
                          File(images[index]),
                          fit: BoxFit.contain,
                        ),
                );
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}