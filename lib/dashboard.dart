import 'package:flutter/material.dart';
import 'package:flutter_application_1/home.dart';
import 'package:flutter_application_1/information.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/widgets/post_card.dart';
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentPageIndex = 0;
  String currentDate = '';
  @override
   void initState() {
    super.initState();
    // Lấy thời gian hiện tại và định dạng nó
    _updateTime();
  }
    void _updateTime() {
    setState(() {
      currentDate = DateFormat('EEEE d, MMMM').format(DateTime.now()); // Định dạng ngày
    });
  }
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _bottomNavBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentDate.isEmpty ? "Loading..." : currentDate,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Greeting and task info
            Text(
              "Chào mừng bạn đọc",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.lightGreenAccent.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Thư viện trường Đại học Đà Lạt",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Marketing",
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                 
                  SizedBox(height: 10),
                  
                  SizedBox(height: 10),
                  Row(
                    
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Date and upcoming events
            Text(
                    "Thông tin",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  PostCard(
                    caption: 'Phòng máy tính TV3 và TV4 với hệ thống trang thiết bị hiện đại, phòng học được trang bị các bộ máy tính được kết nối Internet chất lượng cao.',
                    folderName: 'tv3_4',
                  ),
                  PostCard(
                    caption: 'Cửa ra vào thư viện gồm 2 cửa là cửa chính ở trước thư viện và cửa sau dẫn ra bãi đỗ xe cổng sau, thuận tiện cho việc di chuyển và đảm bảo an ninh.',
                    folderName: 'cua_ra_vao',
                  ),
                  PostCard(
                    caption: 'Hội trường thư viện có không gian rộng lớn, hiện đại, số lượng ghế ngồi rộng lớn với khoảng 300 chỗ. Phòng phù hợp cho các buổi hội thảo, các cuộc họp và sự kiện quan trọng.',
                    folderName: 'hoi_truong_thu_vien',
                  ),
                  // Các bài đăng khác...
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
        } else if (index == 2) {
         
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
          icon: Badge(
            child: Icon(Icons.info_outline),
          ),
          label: 'Thông tin',
        ),
      ],
    );
  }

}
