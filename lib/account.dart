import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/home.dart';
import 'package:flutter_application_1/information.dart';


class AccountPage extends StatefulWidget {
  AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}
  class _AccountPageState extends State<AccountPage>
  {
    int currentPageIndex = 2;


  @override
  Widget build (BuildContext context)
  {
    
    return Scaffold(

      backgroundColor: Color(0xffFFEBCD),
      bottomNavigationBar: _bottomNavBar(),
      appBar: appBar(),
      body: SingleChildScrollView(
       child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child:  ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const Image(image: AssetImage('assets/icon/Rectangle895.png')),
              ),
            ),
            const SizedBox(height: 10),
            Text('Tăng Thế Ngọc Song', style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: Colors.black),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, side:  BorderSide.none, shape: StadiumBorder()
                ),
                ),
            ),
            const Divider(),
            const SizedBox(height: 20),
            MenuMethod(title: 'Thông tin tài khoản', icon: Icons.people),
            const SizedBox(height: 20),
            MenuMethod(title: 'Đổi mật khẩu', icon: Icons.change_circle),
            const SizedBox(height: 20),
            MenuMethod(title: 'Cài đặt', icon: Icons.edit_road),
            const SizedBox(height: 200),
            MenuMethod(title: 'Đăng xuất', icon: Icons.logout),
          ],
        )
       )
      )
    );

  }

  AppBar appBar() {
    return AppBar(
      title: Text(
        'Hồ sơ của bạn',
        style: TextStyle(
          color: Colors.black,

        ),
      ),
      centerTitle: true,
    );
  }
NavigationBar _bottomNavBar() {
    return NavigationBar(
      onDestinationSelected: (int index) {
        setState(() {
          currentPageIndex = index;
        });

        // Điều hướng đến các trang tương ứng khi chọn icon
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage()), // Giữ lại trang HomePage
          );
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => InformationPage()), // Điều hướng đến InformationPage
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AccountPage()), // Điều hướng đến AccountPage
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
  class MenuMethod extends StatelessWidget {
    const MenuMethod({
      Key? key,
      required this.title,
      required this.icon,

    }):super(key: key);
    final String title;
    final IconData icon;
 
    @override
  Widget build(BuildContext context) {
  
    return ListTile(
      tileColor: Colors.white,
     
            leading: Container(
              
              width: 40, height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.white
              ),
              child: Icon(icon),
            ),
            title: Text(title, style: Theme.of(context).textTheme.bodyLarge,),
            trailing: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.grey
              ),
              child: Icon(Icons.arrow_right),
            ),
          );


    
  }

  }
 
