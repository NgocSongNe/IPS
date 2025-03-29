import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/account.dart';
import 'package:flutter_application_1/home.dart';
import 'package:flutter_application_1/models/category_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    // Initialize with some post cards (mô phỏng)
    postCards = List.generate(3, (index) => _buildPostCard());
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
                      imagePath: postImage?.path ?? '',
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
            _buildCategoryButtons(),
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

  Widget _buildCategoryButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _categoryButton('Kệ sách', Icons.book),
            _categoryButton('Khu vực đọc', Icons.menu_book),
            _categoryButton('Phòng vệ sinh', Icons.people),
            _categoryButton('Căn tin', Icons.food_bank),
            _categoryButton('Phòng học', Icons.class_),
            _categoryButton('Phòng thí nghiệm', Icons.science),
            _categoryButton('Phòng máy tính', Icons.computer),
          ],
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

  Widget _buildPostCards() {
    return Column(
      children: postCards,
    );
  }

  Widget _buildPostCard(
      {String caption = 'Mô phỏng nội dung',
      String imagePath = '../assets/new_year_banner.jpg'}) {
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
            padding: const EdgeInsets.all(10.0),
            child: Text(
              caption,
              style: GoogleFonts.openSans(fontSize: 14),
            ),
          ),
          if (imagePath.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(10)),
              child: imagePath.contains('assets')
                  ? Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
            ),
        ],
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
