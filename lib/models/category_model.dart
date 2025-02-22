import 'package:flutter/material.dart';

class CategoryModel {
  String name;
  Icon icons;
  Color boxColor;

  CategoryModel({
    required this.name,
    required this.icons,
    required this.boxColor,

  });
   static List<CategoryModel> getCategories(){
    List<CategoryModel> categories = [];
    
    categories.add(
      CategoryModel(
        name: 'Kệ sách',
        icons: Icon(Icons.book),
        boxColor: Color(0xffE1E1E1)
        
      )
    );
    categories.add(
      CategoryModel(
        name: 'Khu vực đọc',
        icons: Icon(Icons.read_more),
        boxColor: Color(0xffE1E1E1)
      )
    );
    categories.add(
      CategoryModel(
        name: 'Phòng vệ sinh',
        icons: Icon(Icons.wc),
        boxColor: Color(0xffE1E1E1)
      )
    );
    return categories;
  }
}