import 'package:flutter/material.dart';

class MapModel {
  Icon icons;

  MapModel({
    required this.icons,

  });
   static List<MapModel> getMaps(){
    List<MapModel> categories = [];
    
    categories.add(
      MapModel(

        icons: Icon(Icons.book),

      )
    );
    categories.add(
      MapModel(

        icons: Icon(Icons.read_more),
 
      )
    );
    
    return categories;
  }
}