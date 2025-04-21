import 'package:flutter/material.dart';
import 'package:flutter_application_1/POISelectionScreen.dart';
import 'package:flutter_application_1/home.dart'; // Import HomePage
import 'package:google_fonts/google_fonts.dart';

class SuggestedPlacesScreen extends StatefulWidget {
  final POISelectionScreen? poiSelectionScreen;
  final String sourcePage;

  const SuggestedPlacesScreen({
    super.key,
    this.poiSelectionScreen,
    required this.sourcePage,
  });

  @override
  _SuggestedPlacesScreenState createState() => _SuggestedPlacesScreenState();
}

class _SuggestedPlacesScreenState extends State<SuggestedPlacesScreen>
    with SingleTickerProviderStateMixin {
  String? _startPOI;
  String? _endPOI;
  List<Map<String, dynamic>> _poiList = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.poiSelectionScreen != null) {
      _poiList = widget.poiSelectionScreen!.poiList;
    }

    // Khởi tạo animation cho hiệu ứng fade-in
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _drawRoute({required bool showDirections}) {
    if (_startPOI != null && _endPOI != null) {
      widget.poiSelectionScreen?.startPOI = _startPOI;
      widget.poiSelectionScreen?.endPOI = _endPOI;
      widget.poiSelectionScreen?.selectedMarkerRP = _startPOI;
      widget.poiSelectionScreen?.secondSelectedMarkerRP = _endPOI;

      if (showDirections) {
        widget.poiSelectionScreen?.callDrawRouteCD(context, () {
          setState(() {});
        }, showDirections: true);
      } else {
        widget.poiSelectionScreen?.callDrawRoute(context, () {
          setState(() {});
        }, showDirections: false);
      }

      if (widget.sourcePage == 'HomePage') {
        Navigator.pop(context);
      } else if (widget.sourcePage == 'InformationPage') {
        // Không làm gì cả, ở lại SuggestedPlacesScreen
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Vui lòng chọn cả điểm đầu và điểm cuối",
            style: GoogleFonts.openSans(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chọn địa điểm',
          style: GoogleFonts.openSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal.shade50,
              Colors.blue.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildLocationDropdown(
                      'Chọn điểm đầu',
                      Icons.location_pin,
                      true,
                      Colors.red,
                    ),
                    const SizedBox(height: 15),
                    _buildLocationDropdown(
                      'Chọn điểm cuối',
                      Icons.place,
                      false,
                      Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          label: "Tìm đường",
                          icon: Icons.directions,
                          gradient: LinearGradient(
                            colors: [Colors.teal.shade400, Colors.teal.shade600],
                          ),
                          onPressed: () {
                            _drawRoute(showDirections: false);
                          },
                        ),
                        _buildActionButton(
                          label: "Bắt đầu",
                          icon: Icons.play_arrow,
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400, Colors.blue.shade600],
                          ),
                          onPressed: () {
                            _drawRoute(showDirections: false);
                            _drawRoute(showDirections: true);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(
                thickness: 1,
                color: Colors.grey.shade300,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'BẢN ĐỒ',
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: widget.poiSelectionScreen != null
                          ? widget.poiSelectionScreen!.buildMapSection(context, () {
                              setState(() {});
                            })
                          : const Center(child: Text("Không thể tải bản đồ")),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDropdown(
    String hintText,
    IconData icon,
    bool isStartPoint,
    Color iconColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButton<String>(
                hint: Text(
                  hintText,
                  style: GoogleFonts.openSans(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
                value: isStartPoint ? _startPOI : _endPOI,
                isExpanded: true,
                underline: const SizedBox(),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.teal.shade600,
                  size: 28,
                ),
                items: _poiList
                    .where((poi) =>
                        poi['name'] != 'Waypoint' &&
                        !poi['rp'].startsWith('wp_') &&
                        poi['name'] != 'Cầu thang' &&
                        poi['name'] != 'Hành lang')
                    .map((poi) {
                  return DropdownMenuItem<String>(
                    value: poi['rp'] as String,
                    child: Text(
                      poi['name'] as String,
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    if (isStartPoint) {
                      _startPOI = value;
                      widget.poiSelectionScreen?.selectedMarkerRP = value;
                    } else {
                      _endPOI = value;
                      widget.poiSelectionScreen?.secondSelectedMarkerRP = value;
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: GoogleFonts.openSans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}