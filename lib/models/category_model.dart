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
        icons: Icon(Icons.menu_book),
        boxColor: Color(0xffE1E1E1)
      )
    );
    categories.add(
      CategoryModel(
        name: 'Phòng vệ sinh',
        icons: Icon(Icons.people),
        boxColor: Color(0xffE1E1E1)
      )
    );
     categories.add(
      CategoryModel(
        name: 'Căn tin',
        icons: Icon(Icons.food_bank),
        boxColor: Color(0xffE1E1E1)
      )
    );
     categories.add(
      CategoryModel(
        name: 'Khu vực tự học ',
        icons: Icon(Icons.class_),
        boxColor: Color(0xffE1E1E1)
      )
    );
     categories.add(
      CategoryModel(
        name: 'TV3,4',
        icons: Icon(Icons.science),
        boxColor: Color(0xffE1E1E1)
      )
    );
       categories.add(
      CategoryModel(
        name: 'Phòng tạp chí',
        icons: Icon(Icons.science),
        boxColor: Color(0xffE1E1E1)
      )
    );
     categories.add(
      CategoryModel(
        name: 'Hội trường thư viện',
        icons: Icon(Icons.stadium),
        boxColor: Color(0xffE1E1E1)
      )
    );

    return categories;
  }
}