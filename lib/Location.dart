import 'package:flutter/material.dart';
import 'package:flutter_application_1/POISelectionScreen.dart';
import 'package:flutter_application_1/home.dart'; // Import HomePage

class SuggestedPlacesScreen extends StatefulWidget {
  final POISelectionScreen?
      poiSelectionScreen; // Nhận POISelectionScreen từ HomePage
  final String sourcePage; // Xác định trang nguồn

  const SuggestedPlacesScreen({
    super.key,
    this.poiSelectionScreen,
    required this.sourcePage, // Bắt buộc truyền sourcePage
  });

  @override
  _SuggestedPlacesScreenState createState() => _SuggestedPlacesScreenState();
}

class _SuggestedPlacesScreenState extends State<SuggestedPlacesScreen> {
  String? _startPOI; // Điểm đầu được chọn
  String? _endPOI; // Điểm cuối được chọn
  List<Map<String, dynamic>> _poiList =
      []; // Danh sách các POI từ POISelectionScreen

  @override
  void initState() {
    super.initState();
    // Lấy danh sách POI từ POISelectionScreen nếu có
    if (widget.poiSelectionScreen != null) {
      _poiList = widget.poiSelectionScreen!.poiList;
    }
  }

  // Hàm để vẽ đường đi và quay về trang trước
  void _drawRoute({required bool showDirections}) {
    if (_startPOI != null && _endPOI != null) {
      widget.poiSelectionScreen?.startPOI = _startPOI;
      widget.poiSelectionScreen?.endPOI = _endPOI;
      widget.poiSelectionScreen?.selectedMarkerRP = _startPOI;
      widget.poiSelectionScreen?.secondSelectedMarkerRP = _endPOI;

      // Gọi hàm vẽ đường đi từ POISelectionScreen
      if (showDirections) {
        widget.poiSelectionScreen?.callDrawRouteCD(context, () {
          setState(() {});
        }, showDirections: true);
      } else {
        widget.poiSelectionScreen?.callDrawRoute(context, () {
          setState(() {});
        }, showDirections: false);
      }

      // Kiểm tra nguồn trang và điều hướng tương ứng
      if (widget.sourcePage == 'HomePage') {
        // Nếu truy cập từ HomePage, chỉ pop để trở về
        Navigator.pop(context);
      } else if (widget.sourcePage == 'InformationPage') {
        // Nếu truy cập từ InformationPage, không điều hướng, giữ nguyên trang
        // Không làm gì cả, ở lại SuggestedPlacesScreen
      }
    } else {
      // Hiển thị thông báo nếu chưa chọn đủ điểm
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn cả điểm đầu và điểm cuối")),
      );
    }
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
                _buildLocationDropdown(
                    'Chọn điểm đầu', Icons.location_pin, true),
                const SizedBox(height: 10),
                _buildLocationDropdown('Chọn điểm cuối', Icons.place, false),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _drawRoute(showDirections: false); // Tìm đường
                      },
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text(
                        "Tìm đường",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _drawRoute(showDirections: false); // Tìm đường

                        _drawRoute(
                            showDirections:
                                true); // Vẽ đường đi và đọc hướng dẫn
                      },
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text(
                        "Bắt đầu",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(thickness: 1),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'BẢN ĐỒ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: widget.poiSelectionScreen != null
                ? widget.poiSelectionScreen!.buildMapSection(context, () {
                    setState(
                        () {}); // Làm mới giao diện khi có thay đổi trên bản đồ
                  })
                : const Center(child: Text("Không thể tải bản đồ")),
          ),
        ],
      ),
    );
  }

  // Widget để tạo Dropdown (Combo Box) cho điểm đầu và điểm cuối
  Widget _buildLocationDropdown(
      String hintText, IconData icon, bool isStartPoint) {
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
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButton<String>(
                hint: Text(hintText),
                value: isStartPoint ? _startPOI : _endPOI,
                isExpanded: true,
                underline: const SizedBox(), // Ẩn đường gạch dưới mặc định
                items: _poiList
                    .where((poi) =>
                        poi['name'] != 'Waypoint' &&
                        !poi['rp'].startsWith('wp_') &&
                        poi['name'] != 'Cầu thang' && // Loại bỏ "Cầu thang"
                        poi['name'] != 'Hành lang') // Loại bỏ "Hành lang"
                    .map((poi) {
                  return DropdownMenuItem<String>(
                    value: poi['rp'] as String,
                    child: Text(poi['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    if (isStartPoint) {
                      _startPOI = value;
                      widget.poiSelectionScreen?.selectedMarkerRP =
                          value; // Cập nhật điểm đầu
                    } else {
                      _endPOI = value;
                      widget.poiSelectionScreen?.secondSelectedMarkerRP =
                          value; // Cập nhật điểm cuối
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
