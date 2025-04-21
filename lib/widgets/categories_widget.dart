// categories_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category_model.dart';

class CategoriesWidget extends StatelessWidget {
  final List<CategoryModel> categories;
  final Function(String) onCategorySelected;

  CategoriesWidget({required this.categories, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(categories.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
              child: ElevatedButton.icon(
                onPressed: () => onCategorySelected(categories[index].name),
                icon: Icon(
                  categories[index].icons.icon,
                  color: Colors.green,
                ),
                label: Text(categories[index].name),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
