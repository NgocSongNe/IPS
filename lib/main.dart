import 'package:flutter/material.dart';
import 'package:flutter_application_1/welcome_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

class ApiUrlProvider with ChangeNotifier {
  String apiUrl;

  ApiUrlProvider(this.apiUrl);

  void updateApiUrl(String newApiUrl) {
    apiUrl = newApiUrl;
    notifyListeners(); // Notify listeners about the change
  }

}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load file .env trước khi chạy app
  String apiUrl = dotenv.env['API_URL'] ?? 'https://default-api-url.com';
  // Lấy giá trị API_URL từ .env hoặc sử dụng mặc định nếu không tìm thấy

  runApp(MyApp(apiUrl: apiUrl));
  // Yêu cầu quyền sử dụng vị trí và wifi trước khi chạy app
  await requestPermissions();

}

Future<void> requestPermissions() async {
  // Yêu cầu quyền vị trí
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  }

  // Yêu cầu quyền Nearby Wifi Devices trên Android 13+
  if (await Permission.nearbyWifiDevices.isDenied) {
    await Permission.nearbyWifiDevices.request();
  }

  // Mở cài đặt nếu quyền bị từ chối vĩnh viễn
  if (await Permission.location.isPermanentlyDenied ||
      await Permission.nearbyWifiDevices.isPermanentlyDenied) {
    openAppSettings();
  }
}

class MyApp extends StatelessWidget {
  final String apiUrl;

  const MyApp({super.key, required this.apiUrl});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ApiUrlProvider(apiUrl),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'OpenSans'),
        home: WelcomePage(),
      ),
    );
  }
}
