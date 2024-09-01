import 'dart:convert';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/voice_setting_model.dart';

final flutterTtsServiceProvider =
    Provider<FlutterTtsService>((ref) => FlutterTtsService());

class FlutterTtsService {
  final FlutterTts _flutterTts = FlutterTts();

  FlutterTtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ja-JP");
  }

  Future<void> loadVoiceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('voiceSettings');
    if (settingsJson != null) {
      final settings = VoiceSettings.fromJson(json.decode(settingsJson));
      await setSpeed(settings.speed);
      await setVoice(settings.selectedVoice);
    }
  }

  Future<List<String>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return (voices as List<dynamic>)
          .where((voice) => voice['locale'] == 'ja-JP')
          .map((voice) => voice['name'] as String)
          .toList();
    } catch (e) {
      print('Error getting available voices: $e');
      return [];
    }
  }

  Future<void> setSpeed(double speed) async {
    await _flutterTts.setSpeechRate(speed);
  }

  Future<void> setVoice(String voice) async {
    await _flutterTts.setVoice({"name": voice, "locale": "ja-JP"});
    print('Voice set to: $voice'); // デバッグ用
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> pause() async {
    await _flutterTts.pause();
  }

  void setCompletionCallback(VoidCallback callback) {
    _flutterTts.setCompletionHandler(callback);
  }

  void setCompletionHandler(Function() handler) {
    _flutterTts.setCompletionHandler(handler);
  }

  void setErrorHandler(Function(String message) handler) {
    _flutterTts.setErrorHandler((message) => handler(message));
  }

  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }
}
