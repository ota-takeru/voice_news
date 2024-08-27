import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/weather_model.dart';
import '../providers/news_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/location_provider.dart';
import 'news_screen.dart';

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
    final newsState = ref.watch(newsProvider);
    final locationState = ref.watch(locationProvider);
    final weatherState = ref.watch(weatherProvider);
    final formattedDate = DateFormat('yyyy年MM月dd日').format(_currentTime);
    final weekday = _getJapaneseWeekday(_currentTime.weekday);
    final formattedTime = DateFormat('HH:mm').format(_currentTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text('音声ニュース'),
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
                      // locationState.when(
                      //   data: (location) {
                      //     return Column(
                      //       children: [
                      // Semantics(
                      //   label: '現在地',
                      //   value: '${location.city}, ${location.country}',
                      //   child: Text(
                      //     '現在地: ${location.city}, ${location.country}',
                      //     style: const TextStyle(
                      //       fontSize: 18,
                      //       fontWeight: FontWeight.bold,
                      //       color: Colors.green,
                      //     ),
                      //   ),
                      // ),
                      //     ],
                      //   );
                      // },
                      // loading: () => const CircularProgressIndicator(),
                      // error: (error, _) => Text('位置情報の取得に失敗しました: $error'),
                      // ),
                      // const SizedBox(height: 16),
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
              newsState.when(
                data: (_) => Semantics(
                  label: 'ニュースを読むボタン',
                  button: true,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const NewsScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'ニュースを読む',
                      style: TextStyle(
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('エラーが発生しました: $error'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDisplay(WeatherDay weatherDay, String day) {
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
            _getWeatherIcon(weatherDay.condition),
            size: 32,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(
            '${weatherDay.temperature.round()}°C',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _getJapaneseWeatherCondition(weatherDay.condition),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.umbrella;
      default:
        return Icons.cloud_queue;
    }
  }
}
