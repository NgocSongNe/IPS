import 'package:flutter/material.dart';

class SuggestedPlacesScreen extends StatefulWidget {
  const SuggestedPlacesScreen({super.key});

  @override
  _SuggestedPlacesScreenState createState() => _SuggestedPlacesScreenState();
}

class _SuggestedPlacesScreenState extends State<SuggestedPlacesScreen> {
  // Danh sách 40 điểm từ rpToFolderMap
  final Map<String, String> rpToFolderMap = {
    "1": "tv3_4",
    "2": "cua_ra_vao",
    "3": "hoi_truong_thu_vien",
    "4": "cau_thang",
    "5": "cau_thang",
    "6": "cau_thang",
    "7": "cau_thang",
    "8": "khu_vuc_tu_hoc",
    "9": "can_tin",
    "10": "cau_thang",
    "11": "cau_thang",
    "12": "khu_vuc_tu_hoc",
    "13": "khu_vuc_tu_hoc",
    "14": "khu_vuc_tu_hoc",
    "15": "khu_vuc_tu_hoc",
    "16": "hanh_lang",
    "17": "hanh_lang",
    "18": "khu_vuc_tu_hoc",
    "19": "cau_thang",
    "20": "cau_thang",
    "21": "cau_thang",
    "22": "khu_vuc_doc",
    "23": "khu_vuc_tu_hoc",
    "24": "khu_vuc_tu_hoc",
    "25": "khu_vuc_doc",
    "26": "khu_vuc_doc",
    "27": "khu_vuc_doc",
    "28": "cau_thang",
    "29": "cau_thang",
    "30": "khu_vuc_doc",
    "31": "khu_vuc_doc",
    "32": "cau_thang",
    "33": "cau_thang_tang_2",
    "34": "cua_ra_vao",
    "35": "khu_vuc_tu_hoc",
    "36": "ban_thu_thu",
    "37": "ban_thu_thu",
    "38": "khu_vuc_tu_hoc",
    "39": "phong_tap_chi",
    "40": "cau_thang_tang_2",
  };

  // Danh sách các điểm để hiển thị trong combobox
  late List<String> placesList;

  // Biến trạng thái để lưu giá trị được chọn từ 2 combobox
  String? selectedPlace1;
  String? selectedPlace2;

  @override
  void initState() {
    super.initState();
    // Tạo danh sách các điểm từ rpToFolderMap (chỉ lấy giá trị)
    placesList = rpToFolderMap.values.toList();
    // Đặt giá trị mặc định (có thể bỏ trống nếu muốn)
    selectedPlace1 = placesList[0]; // Giá trị mặc định cho combobox 1
    selectedPlace2 = placesList[0]; // Giá trị mặc định cho combobox 2
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFEBCD),
      appBar: AppBar(
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                // Combobox 1 thay thế "Chọn địa điểm"
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedPlace1,
                            isExpanded: true,
                            hint: const Text("Chọn địa điểm"),
                            items: placesList.map((String place) {
                              return DropdownMenuItem<String>(
                                value: place,
                                child: Text(_mapFolderToDisplayName(place)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedPlace1 = newValue;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Combobox 2 thay thế "Chọn địa điểm >"
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.place, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedPlace2,
                            isExpanded: true,
                            hint: const Text("Chọn địa điểm"),
                            items: placesList.map((String place) {
                              return DropdownMenuItem<String>(
                                value: place,
                                child: Text(_mapFolderToDisplayName(place)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedPlace2 = newValue;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1),
          const Padding(
            padding: EdgeInsets.all(16.0),
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
                  title: Text(place['name']!, style: const TextStyle(fontSize: 16)),
                  subtitle: place['subtitle'] != null
                      ? Text(place['subtitle']!,
                          style: const TextStyle(color: Colors.grey))
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

  // Hàm ánh xạ tên folder sang tên hiển thị thân thiện
  String _mapFolderToDisplayName(String folderName) {
    switch (folderName) {
      case "khu_vuc_doc":
        return "Khu vực đọc";
      case "khu_vuc_tu_hoc":
        return "Phòng học";
      case "can_tin":
        return "Căn tin";
      case "hoi_truong_thu_vien":
        return "Phòng thí nghiệm";
      case "ban_thu_thu":
        return "Kệ sách";
      case "phong_tap_chi":
        return "Phòng máy tính";
      case "cua_ra_vao":
        return "Cửa ra vào";
      case "cau_thang":
        return "Cầu thang";
      case "cau_thang_tang_2":
        return "Cầu thang tầng 2";
      case "hanh_lang":
        return "Hành lang";
      case "tv3_4":
        return "TV 3-4";
      default:
        return folderName;
    }
  }
}

final List<Map<String, String>> suggestedPlaces = [
  {'image': '../assets/canteen.jpg', 'name': 'Căn tin trường'},
  {
    'image': '../assets/reading_area.jpg',
    'name': 'Khu vực đọc',
    'subtitle': 'Khu vực đọc 1'
  },
  {
    'image': '../assets/magazine_room.jpg',
    'name': 'Phòng tạp chí',
    'subtitle': 'Phòng tạp chí 1'
  },
  {'image': '../assets/main_entrance.jpg', 'name': 'Cửa chính'},
  {'image': '../assets/info_desk.jpg', 'name': 'Quầy thông tin'},
  {
    'image': '../assets/restroom.jpg',
    'name': 'Phòng vệ sinh',
    'subtitle': 'Phòng vệ sinh 1'
  },
  {
    'image': '../assets/practice_room.jpg',
    'name': 'Phòng thực hành',
    'subtitle': 'Phòng thực hành 3&4'
  },
];
