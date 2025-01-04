import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import 'location_provider.dart';

// WeatherService Provider
final weatherServiceProvider = Provider(
    (ref) => WeatherService(apiKey: '4eda1407359caaa3d45d6be0c34aa401'));

// Weather Provider
final weatherProvider =
    StateNotifierProvider<WeatherNotifier, AsyncValue<Weather>>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  return WeatherNotifier(ref, weatherService);
});

class WeatherNotifier extends StateNotifier<AsyncValue<Weather>> {
  final WeatherService _weatherService;
  final Ref _ref;

  // デフォルトの位置情報を定義
  static Location defaultLocation = Location(
    city: "Tokyo",
    country: "Japan",
    latitude: 35.6762,
    longitude: 139.6503,
  );

  WeatherNotifier(this._ref, this._weatherService)
      : super(const AsyncValue.loading());

  Future<void> fetchWeather() async {
    state = const AsyncValue.loading();

    final locationState = _ref.read(locationProvider);

    Location locationToUse;

    if (locationState is AsyncData<Location>) {
      locationToUse = locationState.value;
    } else {
      // 位置情報の取得に失敗した場合やローディング中の場合、デフォルトの位置情報を使用
      locationToUse = defaultLocation;
    }

    try {
      final weather = await _weatherService.fetchWeatherForecast(
          latitude: locationToUse.latitude, longitude: locationToUse.longitude);

      if (mounted) {
        state = AsyncValue.data(weather);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(_getErrorMessage(e), stackTrace);
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is NetworkError) {
      return 'ネットワークエラーが発生しました。インターネット接続を確認してください。';
    } else if (error is ApiException) {
      return 'APIエラーが発生しました。しばらくしてからもう一度お試しください。';
    } else {
      return '天気情報の取得中に予期せぬエラーが発生しました。';
    }
  }
}

// エラークラスの定義
class NetworkError implements Exception {}

class ApiException implements Exception {}

class LocationError implements Exception {}
