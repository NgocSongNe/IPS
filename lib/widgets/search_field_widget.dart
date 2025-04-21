// search_field_widget.dart
import 'package:flutter/material.dart';

class SearchFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  SearchFieldWidget({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSearch, // Dùng onTap để thực hiện tìm kiếm khi người dùng nhấn vào trường tìm kiếm
      child: Container(
      margin: EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          )
        ],
      ),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '   Tìm kiếm địa điểm ...',
            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 18),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.mic, color: Colors.black),
                  onPressed: onSearch, // Giữ logic tìm kiếm tại đây
                ),
                IconButton(
                  icon: Icon(Icons.search, color: Colors.black),
                  onPressed: onSearch, // Giữ logic tìm kiếm tại đây
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
