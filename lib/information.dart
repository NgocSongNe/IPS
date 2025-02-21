import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/account.dart';
import 'package:flutter_application_1/home.dart';
import 'package:flutter_application_1/information.dart';
import 'package:flutter_application_1/models/category_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class InformationPage extends StatefulWidget {
  InformationPage({super.key});
  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  int currentPageIndex = 1;
  List<CategoryModel> categories = [];

  void getCategories() {
    categories = CategoryModel.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    getCategories();
    return Scaffold(
      backgroundColor: Color(0xffFFEBCD),
      bottomNavigationBar: _bottomNavBar(),
      body: Column(
        children: [
          _searchField(),
          SizedBox(height: 25),
          Container(
            width: 50,
            decoration: BoxDecoration(
              color: Colors.blueGrey,
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

        // Điều hướng đến các trang tương ứng khi chọn icon
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => HomePage()), // Giữ lại trang HomePage
          );
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    InformationPage()), // Điều hướng đến InformationPage
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AccountPage()), // Điều hướng đến AccountPage
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

  Container _searchField() {
    return Container(
      margin: EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0xff1D1617), blurRadius: 5, spreadRadius: 0.0)
        ],
      ),
      child: TextFormField(
        decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search',
            hintStyle:
                GoogleFonts.openSans(color: Color(0xff888888), fontSize: 14),
            prefixIcon: Icon(
              Icons.search,
              size: 25,
            )),
      ),
    );
  }
}
