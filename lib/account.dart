import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/home.dart';
import 'package:flutter_application_1/information.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int currentPageIndex = 2;
  String? username; // null nếu chưa đăng nhập
  String? password;
  File? profileImage;
  bool isLoggedIn = false; // Trạng thái đăng nhập

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      username = prefs.getString('username') ?? 'NgocSong';
      password = prefs.getString('password') ?? '123456';
      String? imagePath = prefs.getString('profileImagePath');
      if (imagePath != null) profileImage = File(imagePath);
    });
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
    if (isLoggedIn) {
      await prefs.setString('username', username!);
      await prefs.setString('password', password!);
    }
  }

  Future<void> _pickImage() async {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng đăng nhập trước!')),
      );
      return;
    }
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', pickedFile.path);
    }
  }

  void _changePassword() {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng đăng nhập trước!')),
      );
      return;
    }
    String newPassword = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đổi mật khẩu'),
        content: TextField(
          onChanged: (value) => newPassword = value,
          decoration: InputDecoration(labelText: 'Nhập mật khẩu mới'),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (newPassword.isNotEmpty) {
                setState(() {
                  password = newPassword;
                });
                _saveUserData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đổi mật khẩu thành công!')),
                );
              }
            },
            child: Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _login() {
    showDialog(
      context: context,
      builder: (context) {
        String inputUsername = '';
        String inputPassword = '';
        return AlertDialog(
          title: Text('Đăng nhập'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => inputUsername = value,
                decoration: InputDecoration(labelText: 'Tên tài khoản'),
              ),
              TextField(
                onChanged: (value) => inputPassword = value,
                decoration: InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (inputUsername == 'NgocSong' && inputPassword == '123456') {
                  setState(() {
                    isLoggedIn = true;
                    username = inputUsername;
                    password = inputPassword;
                  });
                  _saveUserData();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đăng nhập thành công!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tài khoản hoặc mật khẩu sai!')),
                  );
                }
              },
              child: Text('Đăng nhập'),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    if (!isLoggedIn) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận đăng xuất'),
        content: Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              setState(() {
                isLoggedIn = false;
                username = null;
                password = null;
                profileImage = null;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đăng xuất thành công!')),
              );
            },
            child: Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoogleFonts.openSans(),
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: _bottomNavBar(),
        appBar: appBar(),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _profileSection(),
              const SizedBox(height: 20),
              _menuItem('Thông tin tài khoản', Icons.person),
              _menuItem('Đổi mật khẩu', Icons.lock, _changePassword),
              _menuItem('Đổi ảnh đại diện', Icons.image, _pickImage),
              _menuItem('Cài đặt', Icons.settings, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chức năng đang phát triển!')),
                );
              }),
              const SizedBox(height: 20),
              isLoggedIn ? _logoutButton() : _loginButton(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'HỒ SƠ CỦA BẠN',
        style: GoogleFonts.openSans(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _profileSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: isLoggedIn ? _pickImage : _login,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 3),
              borderRadius: BorderRadius.circular(100),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: profileImage != null
                  ? Image.file(
                      profileImage!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      '../assets/avt_st.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          username ?? 'Chưa đăng nhập',
          style: GoogleFonts.openSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _menuItem(String title, IconData icon, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.amber),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.openSans(fontSize: 16),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: _logout,
        child: Text(
          'Đăng xuất',
          style: GoogleFonts.openSans(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _loginButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: _login,
        child: Text(
          'Đăng nhập',
          style: GoogleFonts.openSans(fontSize: 16, color: Colors.white),
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
