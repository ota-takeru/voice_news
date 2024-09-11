import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/location_provider.dart';
import '../providers/news_provider.dart';
import '../providers/weather_provider.dart';

class StartScreenController extends StateNotifier<void> {
  StartScreenController(this.ref) : super(null) {
    _initializeData();
  }

  final Ref ref;
  final FlutterTts flutterTts = FlutterTts();

  Future<void> _initializeData() async {
    await ref.read(locationProvider.notifier).fetchLocation();
    await ref.read(weatherProvider.notifier).fetchWeather();
    await ref.read(newsProvider.notifier).fetchNews();
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

  Future<void> speakTimeAndWeather() async {
    final weatherState = ref.read(weatherProvider);
    final timeString = DateFormat('HH時mm分').format(DateTime.now());
    String speechText = "現在の時刻は$timeStringです。";
    weatherState.when(
      data: (weather) {
        final todayWeatherString =
            '今日の天気は${_getJapaneseWeatherCondition(weather.today.condition)}で、気温は${weather.today.temperature.round()}度です';
        final tomorrowWeatherString =
            '明日の天気は${_getJapaneseWeatherCondition(weather.tomorrow.condition)}で、気温は${weather.tomorrow.temperature.round()}度の予報です';
        speechText += "$todayWeatherString。$tomorrowWeatherString";
      },
      loading: () {
        speechText += "天気情報を読み込み中です。";
      },
      error: (error, _) {
        speechText += "天気情報は現在取得できません。";
      },
    );

    await flutterTts.setLanguage("ja-JP");
    await flutterTts.speak(speechText);
  }
}

final startScreenControllerProvider =
    StateNotifierProvider<StartScreenController, void>((ref) {
  return StartScreenController(ref);
});
