// category_button_widget.dart
import 'package:flutter/material.dart';

class CategoryButtonWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  CategoryButtonWidget({required this.title, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
