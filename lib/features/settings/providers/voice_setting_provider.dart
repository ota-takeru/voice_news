import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/voice_setting_model.dart';
import '../services/flutter_tts_service.dart';

final voiceSettingsProvider =
    StateNotifierProvider<VoiceSettingsNotifier, VoiceSettings>((ref) {
  return VoiceSettingsNotifier(ref.watch(flutterTtsServiceProvider));
});

class VoiceSettingsNotifier extends StateNotifier<VoiceSettings> {
  final FlutterTtsService _ttsService;
  static const String _settingsKey = 'voiceSettings';

  VoiceSettingsNotifier(this._ttsService)
      : super(
            VoiceSettings(speed: 1.0, selectedVoice: '', availableVoices: [])) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson != null) {
      state = VoiceSettings.fromJson(json.decode(settingsJson));
    } else {
      await _setDefaultSettings();
    }
    await _updateAvailableVoices();
    if (state.selectedVoice.isEmpty && state.availableVoices.isNotEmpty) {
      await setSelectedVoice(state.availableVoices.first);
    }
  }

  Future<void> _updateAvailableVoices() async {
    final voices = await _ttsService.getAvailableVoices();
    state = state.copyWith(availableVoices: voices);
  }

  Future<void> _setDefaultSettings() async {
    final voices = await _ttsService.getAvailableVoices();
    final defaultVoice = _getDefaultVoice(voices);
    state = VoiceSettings(
      speed: 1.0,
      selectedVoice: defaultVoice,
      availableVoices: voices,
    );
    await _saveSettings();
  }

  String _getDefaultVoice(List<String> voices) {
    // デフォルト（女性音声1）を最優先
    final defaultVoice = voices
        .firstWhere((voice) => voice.contains('-jab-') && isOfflineVoice(voice),
            orElse: () {
      // デフォルトが見つからない場合は、他の日本語オフライン音声を探す
      final japaneseOfflineVoices = voices
          .where((voice) => voice.startsWith('ja-jp') && isOfflineVoice(voice))
          .toList();

      if (japaneseOfflineVoices.isNotEmpty) {
        return japaneseOfflineVoices.first;
      }

      // 日本語オフライン音声がない場合は、任意のオフライン音声
      final offlineVoices = voices.where(isOfflineVoice).toList();
      if (offlineVoices.isNotEmpty) {
        return offlineVoices.first;
      }

      // オフライン音声がない場合は、最初の音声を返す
      return voices.first;
    });

    return defaultVoice;
  }

  bool isOfflineVoice(String voice) {
    final parts = voice.split('-');
    return parts.length >= 5 && parts[4] == 'local';
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(state.toJson()));
  }

  void setSpeed(double speed) {
    state = state.copyWith(speed: speed);
    _ttsService.setSpeed(speed);
    _saveSettings();
  }

  Future<void> setSelectedVoice(String voice) async {
    state = state.copyWith(selectedVoice: voice);
    await _ttsService.setVoice(voice);
    await _saveSettings();
  }
}
