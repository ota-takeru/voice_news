import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_news/features/news/providers/news_provider.dart'; // newsProviderをインポート
import 'package:voice_news/features/settings/services/flutter_tts_service.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../providers/location_provider.dart';
import '../providers/weather_provider.dart';

final startScreenControllerProvider =
    StateNotifierProvider<StartScreenController, void>(
        (ref) => StartScreenController(ref));

class StartScreenController extends StateNotifier<void> {
  StartScreenController(this._ref) : super(null);

  final Ref _ref;

  // データ初期化用のメソッド
  Future<void> initializeData() async {
    await _ref.read(locationProvider.notifier).fetchLocation();
    await _ref.read(weatherProvider.notifier).fetchWeather();
    await _fetchNewsData(); // ニュース取得処理を呼び出し
  }

  // 時刻と天気を読み上げるメソッド
  Future<void> speakTimeAndWeather() async {
    final ttsService = _ref.read(flutterTtsServiceProvider);
    final weatherState = _ref.read(weatherProvider);
    final locationState = _ref.read(locationProvider);

    String weatherText = '';
    if (weatherState is AsyncData<Weather>) {
      final weather = weatherState.value;
      final condition = _getJapaneseWeatherCondition(weather.today.condition);

      weatherText = '。天気は${condition}です';
    }

    String locationText = '';

    if (locationState is AsyncData<Location>) {
      final location = locationState.value;
      locationText = '${location.city}の天気';
    }

    final currentTime = DateTime.now();
    final formattedTime = DateFormat('a h時mm分', 'ja_JP').format(currentTime);

    await ttsService.speak('$locationText 現在の時刻は、$formattedTime$weatherText');
  }

  // 天気状態を日本語に変換するメソッド
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

  // ニュースデータを取得・更新するメソッド
  Future<void> _fetchNewsData() async {
    final prefs = await SharedPreferences.getInstance();
    final keywords = prefs.getStringList('saved_keywords') ?? [];

    // トップニュースの取得
    await _ref.read(newsProvider(null).notifier).fetchNews();

    // キーワードニュースの取得
    for (final keyword in keywords) {
      await _ref.read(newsProvider(keyword).notifier).fetchNews(keyword);
    }
  }
}
