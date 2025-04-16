import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialOverlay extends StatefulWidget {
  final Widget child;
  final void Function(String)? onPOITap;
  final void Function()? onNavigateToInformation;
  final bool startTutorial;

  const TutorialOverlay({
    super.key,
    required this.child,
    this.onPOITap,
    this.onNavigateToInformation,
    this.startTutorial = false,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  bool _showOverlay = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _checkIfTutorialSeen();
  }

  Future<void> _checkIfTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;

    if (!hasSeenTutorial && widget.startTutorial) {
      setState(() {
        _showOverlay = true;
      });
    }
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', true);
    setState(() {
      _showOverlay = false;
      _currentStep = 0;
    });
  }

  void _nextStep() {
    setState(() {
      if (_currentStep == 0) {
        // Bước 1: HomePage -> Mở POI
        if (widget.onPOITap != null) {
          widget.onPOITap!("TV3,4");
        } else {
          print("onPOITap không được cung cấp.");
        }
        _currentStep++;
      } else if (_currentStep == 1) {
        // Bước 2: HomePage (sau khi mở POI) -> InformationPage
        if (widget.onNavigateToInformation != null) {
          widget.onNavigateToInformation!();
        } else {
          print("onNavigateToInformation không được cung cấp.");
        }
        _currentStep++;
      } else {
        // Bước 3: InformationPage -> Kết thúc
        _completeTutorial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showOverlay)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep == 0
                        ? "Đây là màn hình chính của ứng dụng, tại đây bạn có thể xem thông tin bản đồ và tìm đường đi giữa các địa điểm."
                        : _currentStep == 1
                            ? "Khi nhấn vào một địa điểm trên bản đồ Thư viện, bạn có thể xem thông tin mô tả cũng như hình ảnh của địa điểm đó. Đồng thời bạn cũng có thể thao tác để tìm đường đến đó."
                            : "Đây là trang thông tin, tại đây bạn có thể xem các bài đăng và tìm kiếm địa điểm trong thư viện.",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _nextStep,
                    child: Text(
                      _currentStep == 2 ? "Kết thúc" : "Tiếp tục",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _completeTutorial,
                    child: const Text(
                      "Bỏ qua",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
