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

  WeatherNotifier(this._ref, this._weatherService)
      : super(const AsyncValue.loading());

  Future<void> fetchWeather() async {
    final locationState = _ref.read(locationProvider);

    if (locationState is AsyncData<Location>) {
      final location = locationState.value;
      try {
        state = const AsyncValue.loading();
        final weather = await _weatherService.fetchWeatherForecast(
            latitude: location.latitude, longitude: location.longitude);

        state = AsyncValue.data(weather);
      } on NetworkError {
        state = AsyncValue.error("ネットワークエラーが発生しました。", StackTrace.current);
      } on ApiException {
        state = AsyncValue.error("APIエラーが発生しました。", StackTrace.current);
      } catch (e) {
        state = AsyncValue.error("エラーが発生しました。no response", StackTrace.current);
      }
    } else if (locationState is AsyncError) {
      state = AsyncValue.error("位置情報の取得に失敗しました。", StackTrace.current);
    } else {
      state = const AsyncValue.loading();
    }
  }
}

// エラークラスの定義
class NetworkError implements Exception {}

class ApiException implements Exception {}

class LocationError implements Exception {}
