import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/screens/setting_screen.dart';
import '../../settings/services/flutter_tts_service.dart';
import '../controller/start_screen_controller.dart';
import '../widgets/news_button.dart';
import '../widgets/time_display_widget.dart';
import '../widgets/weather_widget.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() async {
    final ttsService = ref.read(flutterTtsServiceProvider);
    await ttsService.loadVoiceSettings();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(startScreenControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('音声ニュース'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              size: 36,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 20)
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const TimeDisplayWidget(),
                      const SizedBox(height: 16),
                      const WeatherWidget(),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: controller.speakTimeAndWeather,
                        icon: const Icon(Icons.volume_up, size: 20),
                        label: const Text('時刻と天気を読み上げる'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
              const NewsButton(),
            ],
          ),
        ),
      ),
    );
  }
}
