import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_news/themes/app_colors.dart';
import '../providers/voice_setting_provider.dart';
import '../services/flutter_tts_service.dart';

class VoiceSettingsScreen extends ConsumerWidget {
  const VoiceSettingsScreen({super.key});

  String formatVoiceName(String voice) {
    if (Platform.isAndroid) {
      final parts = voice.split('-');
      if (parts.length >= 4 && parts[0] == 'ja' && parts[1] == 'jp') {
        final voiceType = parts[3];

        switch (voiceType) {
          case 'language':
            return 'デフォルト（女性音声1）';
          case 'jab':
            return '女性音声1(デフォルト)';
          case 'jac':
            return '男性音声2';
          case 'jad':
            return '男性音声1';
          case 'htm':
            return '女性音声2';
          default:
            return '音声 $voiceType';
        }
      }
    }
    return voice;
  }

  bool isOfflineVoice(String voice) {
    final parts = voice.split('-');
    return parts.length >= 5 && parts[4] == 'local';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceSettings = ref.watch(voiceSettingsProvider);
    final voiceSettingsNotifier = ref.read(voiceSettingsProvider.notifier);
    final ttsService = ref.read(flutterTtsServiceProvider);

    final offlineVoices = voiceSettings.availableVoices
        .where(isOfflineVoice)
        .toList()
      ..sort((a, b) => formatVoiceName(a).compareTo(formatVoiceName(b)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('音声設定'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text(
              '読み上げ速度',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSpeedButton(context, '遅い', 0.75, voiceSettingsNotifier),
                _buildSpeedButton(context, '標準', 1.0, voiceSettingsNotifier),
                _buildSpeedButton(context, '速い', 1.25, voiceSettingsNotifier),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Slider(
              value: voiceSettings.speed,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: voiceSettings.speed.toStringAsFixed(2),
              onChanged: (value) => voiceSettingsNotifier.setSpeed(value),
              semanticFormatterCallback: (double value) =>
                  '速度: ${value.toStringAsFixed(2)}',
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primary.withOpacity(0.3),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text(
              '音声の選択',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...offlineVoices.map((voice) => RadioListTile<String>(
                title: Text(formatVoiceName(voice)),
                value: voice,
                groupValue: voiceSettings.selectedVoice,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    voiceSettingsNotifier.setSelectedVoice(newValue);
                  }
                },
                activeColor: AppColors.primary,
              )),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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

  Widget _buildSpeedButton(BuildContext context, String label, double speed,
      VoiceSettingsNotifier notifier) {
    return ElevatedButton(
      onPressed: () => notifier.setSpeed(speed),
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.text,
        backgroundColor: AppColors.background,
        side: const BorderSide(color: AppColors.primary),
      ),
      child: Text(label),
    );
  }
}
