// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> initTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(1);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speakDirections(List<String> directions) async {
    for (String direction in directions) {
      await _flutterTts.speak(direction);
      await Future.delayed(Duration(seconds: 2));
    }
  }
}
