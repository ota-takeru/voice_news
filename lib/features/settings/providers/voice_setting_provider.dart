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
    }
    _updateAvailableVoices();
  }

  Future<void> _updateAvailableVoices() async {
    final voices = await _ttsService.getAvailableVoices();
    state = state.copyWith(availableVoices: voices);
    if (!voices.contains(state.selectedVoice)) {
      setSelectedVoice(voices.first);
    }
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
