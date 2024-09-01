import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_news/themes/app_colors.dart';
import '../providers/voice_setting_provider.dart';
import '../services/flutter_tts_service.dart';

class VoiceSettingsScreen extends ConsumerWidget {
  const VoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceSettings = ref.watch(voiceSettingsProvider);
    final voiceSettingsNotifier = ref.read(voiceSettingsProvider.notifier);
    final ttsService = ref.read(flutterTtsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('音声設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('読み上げ速度'),
            subtitle: Slider(
              value: voiceSettings.speed,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: voiceSettings.speed.toStringAsFixed(2),
              onChanged: (value) => voiceSettingsNotifier.setSpeed(value),
            ),
          ),
          ListTile(
            title: const Text('音声の選択'),
            subtitle: DropdownButton<String>(
              value: voiceSettings.selectedVoice,
              isExpanded: true,
              items: voiceSettings.availableVoices.map((String voice) {
                return DropdownMenuItem<String>(
                  value: voice,
                  child: Text(voice),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  voiceSettingsNotifier.setSelectedVoice(newValue);
                }
              },
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: () async {
                await ttsService.speak("これはテストの音声です。");
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('テスト再生', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
