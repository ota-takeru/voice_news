import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

import '../../settings/screens/setting_screen.dart';
import '../models/weather_model.dart';
import '../providers/news_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/controls/news_button.dart';
import '../widgets/manage_keyword_widget.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    _initializeData();
  }

  Future<void> _initializeData() async {
    await ref.read(locationProvider.notifier).fetchLocation();
    await ref.read(weatherProvider.notifier).fetchWeather();
    await ref.read(newsProvider.notifier).fetchNews();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _speakTimeAndWeather(Weather weather) async {
    final timeString = DateFormat('HH時mm分').format(_currentTime);
    final todayWeatherString =
        '今日の天気は${_getJapaneseWeatherCondition(weather.today.condition)}で、気温は${weather.today.temperature.round()}度です';
    final tomorrowWeatherString =
        '明日の天気は${_getJapaneseWeatherCondition(weather.tomorrow.condition)}で、気温は${weather.tomorrow.temperature.round()}度の予報です';
    await flutterTts.setLanguage("ja-JP");
    await flutterTts.speak(
        "現在の時刻は$timeStringです。$todayWeatherString。$tomorrowWeatherString");
  }

  String _getJapaneseWeatherCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '晴れ';
      case 'clouds':
        return '曇り';
      case 'rain':
        return '雨';
      default:
        return condition;
    }
  }

  String _getJapaneseWeekday(int weekday) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch(newsProvider) は不要になり、NewsButton 側で監視する
    final weatherState = ref.watch(weatherProvider);

    final formattedDate = DateFormat('yyyy年MM月dd日').format(_currentTime);
    final weekday = _getJapaneseWeekday(_currentTime.weekday);
    final formattedTime = DateFormat('HH:mm').format(_currentTime);

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
          const SizedBox(width: 20),
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
                      Semantics(
                        label: '日付',
                        value: '$formattedDate ($weekday)',
                        child: Text(
                          '$formattedDate ($weekday)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        label: '現在時刻',
                        value: formattedTime,
                        child: Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 天気表示
                      weatherState.when(
                        data: (weather) => Column(
                          children: [
                            _buildWeatherDisplay(weather.today, "今日"),
                            const SizedBox(height: 8),
                            _buildWeatherDisplay(weather.tomorrow, "明日"),
                          ],
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stackTrace) {
                          return Text('天気情報の取得に失敗しました: $error');
                        },
                      ),
                      const SizedBox(height: 16),
                      // 時刻と天気を読み上げるボタン
                      Semantics(
                        label: '時刻と天気を読み上げるボタン',
                        button: true,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (weatherState.value != null) {
                              _speakTimeAndWeather(weatherState.value!);
                            }
                          },
                          icon: const Icon(Icons.volume_up, size: 20),
                          label: const Text('時刻と天気を読み上げる'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),

              // ★ ここからが変更点:
              //    もともと newsState.when(...) + ElevatedButton.icon(...) だった箇所を
              //    NewsButton に置き換える。
              //    NewsButton 内部ですでに newsProvider を監視し、ニュースが空ならテキスト、
              //    そうでなければ「ニュースを読む」ボタンなどを返す仕組み。

              const NewsButton(),

              const SizedBox(height: 40),
              const ManageKeywordWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDisplay(WeatherDay weatherDay, String day) {
    final (color, icon) = _getWeatherColorAndIcon(weatherDay.condition);
    return Semantics(
      label: '$dayの天気',
      value:
          '${_getJapaneseWeatherCondition(weatherDay.condition)}、気温${weatherDay.temperature.round()}度',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day: ',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            '${weatherDay.temperature.round()}°C',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _getJapaneseWeatherCondition(weatherDay.condition),
            style: TextStyle(
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _getWeatherColorAndIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return (Colors.orange, Icons.wb_sunny);
      case 'clouds':
        return (Colors.grey, Icons.cloud);
      case 'rain':
        return (Colors.blue, Icons.umbrella);
      default:
        return (Colors.blueGrey, Icons.cloud_queue);
    }
  }
}
