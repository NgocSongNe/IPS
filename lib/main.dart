import 'package:flutter/material.dart';
import 'package:flutter_application_1/Location.dart';
import 'package:flutter_application_1/home.dart';
import 'package:flutter_application_1/Location.dart';
import 'package:flutter_application_1/welcome_screen.dart';
import 'package:flutter_application_1/ultils/permission.dart';
import 'package:permission_handler/permission_handler.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  requestPermissions();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

 Future<void> requestPermissions() async {
  // Yêu cầu quyền vị trí
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  }

  // Nếu chạy trên Android 13+, cần quyền NEARBY_WIFI_DEVICES
  if (await Permission.nearbyWifiDevices.isDenied) {
    await Permission.nearbyWifiDevices.request();
  }

  // Mở cài đặt nếu quyền bị từ chối vĩnh viễn
  if (await Permission.location.isPermanentlyDenied ||
      await Permission.nearbyWifiDevices.isPermanentlyDenied) {
    openAppSettings();
  }
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'OpenSans'),
      home: WelcomePage(),
    );
  }
}