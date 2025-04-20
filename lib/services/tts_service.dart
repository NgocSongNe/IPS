// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  // Hàm khởi tạo TTS
  Future<void> initTts() async {
    print("Initializing TTS...");
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
      print("TTS Initialized.");
  }

  // Hàm phát âm hướng dẫn
  Future<void> speakDirections(List<String> directions, List<double> segmentDistances) async {
    if (directions.isEmpty) return;
    for (int i = 0; i < directions.length; i++) {
      String direction = directions[i];
      String distanceText = i < segmentDistances.length
          ? " ${segmentDistances[i].toStringAsFixed(2)} mét"
          : "";
      String textToSpeak = "$direction$distanceText";
      await _flutterTts.speak(textToSpeak);
      print("Speaking: $textToSpeak"); 
      await Future.delayed(Duration(seconds: 2));
    }
  }
}
