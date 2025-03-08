import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/controller/location_permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestedPlacesScreen extends StatelessWidget {
  const SuggestedPlacesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFEBCD),
      appBar: AppBar(
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildLocationInput('Vị trí của bạn', Icons.location_on, true),
                SizedBox(height: 10),
                _buildLocationInput('Chọn vị trí >', Icons.place, false),
              ],
            ),
          ),
          Divider(thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'ĐIỂM GỢI Ý',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: suggestedPlaces.length,
              itemBuilder: (context, index) {
                final place = suggestedPlaces[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(
                      place['image']!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(place['name']!, style: TextStyle(fontSize: 16)),
                  subtitle: place['subtitle'] != null
                      ? Text(place['subtitle']!,
                          style: TextStyle(color: Colors.grey))
                      : null,
                  onTap: () {
                    // Thực hiện hành động khi nhấn vào địa điểm
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput(
      String text, IconData icon, bool isCurrentLocation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.red),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: text,
                  border: InputBorder.none,
                ),
                readOnly: isCurrentLocation,
                onTap: isCurrentLocation ? null : () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final List<Map<String, String>> suggestedPlaces = [
  {'image': 'assets/canteen.jpg', 'name': 'Căn tin trường'},
  {
    'image': 'assets/reading_area.jpg',
    'name': 'Khu vực đọc',
    'subtitle': 'Khu vực đọc 1'
  },
  {
    'image': 'assets/magazine_room.jpg',
    'name': 'Phòng tạp chí',
    'subtitle': 'Phòng tạp chí 1'
  },
  {'image': 'assets/main_entrance.jpg', 'name': 'Cửa chính'},
  {'image': 'assets/info_desk.jpg', 'name': 'Quầy thông tin'},
  {
    'image': 'assets/restroom.jpg',
    'name': 'Phòng vệ sinh',
    'subtitle': 'Phòng vệ sinh 1'
  },
  {
    'image': 'assets/practice_room.jpg',
    'name': 'Phòng thực hành',
    'subtitle': 'Phòng thực hành 3&4'
  },
];
