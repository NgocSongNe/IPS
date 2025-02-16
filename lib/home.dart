import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Location.dart';
import 'package:flutter_application_1/account.dart';
import 'package:flutter_application_1/information.dart';
import 'package:flutter_application_1/models/category_model.dart';
import 'package:flutter_application_1/models/map_model.dart';
import 'package:flutter/widgets.dart'; // Import thêm package nếu cần để sử dụng Navigator

class HomePage extends StatefulWidget {
  HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
   TextEditingController searchPlaceController = TextEditingController();
  int currentPageIndex = 0;
  List<CategoryModel> categories = [];
  List<MapModel> maps=[];
  void getCategories() {
    categories = CategoryModel.getCategories();
  }
  void getMaps() {
    maps = MapModel.getMaps();
  }

  @override
  Widget build(BuildContext context) {
    getCategories();
    getMaps();
    return Scaffold(
      backgroundColor: Color(0xffFFEBCD),
      bottomNavigationBar: _bottomNavBar(),
      body: Column(
        children: [
          _searchField(),
          SizedBox(height: 25),
          _categoriesMethod(),
           SizedBox(height: 25),
          
          Container(
                width: 378,
              height: 600,
              decoration: BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.circular(25),
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
        currentPageIndex = 0; // Cập nhật currentPageIndex khi chọn mục mới
      });

      // Điều hướng đến các trang tương ứng khi chọn icon
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
    selectedIndex: currentPageIndex, // Cập nhật trạng thái selected icon
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

  Container _categoriesMethod() {
    return Container(
      height: 40,
      child: ListView.separated(
        itemCount: categories.length,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: 10, right: 20),
        separatorBuilder: (context, index) => SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Container(
            width:180,
            decoration: BoxDecoration(
                color: categories[index].boxColor,
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  width: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: categories[index].icons,
                  ),
                ),
                Text(
                  categories[index].name,
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Container _searchField() {
    return Container(
      margin: EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0xff1D1617).withOpacity(0.11),
              blurRadius: 10,
              spreadRadius: 0.0)
        ],
      ),
      child: TextFormField(
        controller: searchPlaceController,
        onTap: (){
           Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LocationPage()),
        );
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search',
          hintStyle: TextStyle(
            color: Colors.green,
            fontSize: 20
          ),
          

          prefixIcon: Icon(
           Icons.gps_fixed,
           size: 25
            ),
          
          suffixIcon: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                VerticalDivider(
                  color: Colors.black,
                  indent: 10,
                  endIndent: 10,
                  thickness: 0.1,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.search)
                ),
              ],
            ),
          ),
          
        ),
      ),
    );
  }
}
