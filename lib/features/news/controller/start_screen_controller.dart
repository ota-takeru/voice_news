import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:voice_news/features/settings/services/flutter_tts_service.dart';
import '../providers/location_provider.dart';
import '../providers/news_provider.dart';
import '../providers/weather_provider.dart';

class StartScreenController extends StateNotifier<void> {
  StartScreenController(this._ref) : super(null) {
    _initializeData();
  }

  final Ref _ref;

  Future<void> _initializeData() async {
    await _ref.read(locationProvider.notifier).fetchLocation();
    await _ref.read(weatherProvider.notifier).fetchWeather();
    await _ref.read(newsProvider.notifier).fetchNews();
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
    final ttsService = _ref.read(flutterTtsServiceProvider);
    final weatherState = _ref.read(weatherProvider);
    final timeString = DateFormat('HH時mm分').format(DateTime.now());
    String speechText = "現在の時刻は$timeStringです。";
    weatherState.when(
      data: (weather) {
        final todayWeatherString =
            '今日の天気は${_getJapaneseWeatherCondition(weather.today.condition)}で、気温は${weather.today.temperature.round()}度、降水確率は${(weather.today.precipProbability * 100).round()}%です。';
        final tomorrowWeatherString =
            '明日の天気は${_getJapaneseWeatherCondition(weather.tomorrow.condition)}で、気温は${weather.tomorrow.temperature.round()}度、降水確率は${(weather.tomorrow.precipProbability * 100).round()}%の予報です。';
        speechText += "$todayWeatherString。$tomorrowWeatherString";
      },
      loading: () {
        speechText += "天気情報を読み込み中です。";
      },
      error: (error, _) {
        speechText += "天気情報は現在取得できません。";
      },
    );

    await ttsService.speak(speechText);
  }
}

final startScreenControllerProvider =
    StateNotifierProvider<StartScreenController, void>((ref) {
  return StartScreenController(ref);
});
