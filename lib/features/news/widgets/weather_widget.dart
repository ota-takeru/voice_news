import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather_model.dart';
import '../providers/location_provider.dart';
import '../providers/weather_provider.dart';

class WeatherWidget extends ConsumerWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(weatherProvider);

    return weatherState.when(
      data: (weather) => Column(
        children: [
          _buildWeatherDisplay(weather.today, "今日"),
          const SizedBox(height: 8),
          _buildWeatherDisplay(weather.tomorrow, "明日"),
        ],
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 28),
              SizedBox(width: 8),
              Text('天気を取得できませんでした'),
            ],
          ),
          Text(error.toString()),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await ref.read(locationProvider.notifier).fetchLocation();
              await ref.read(weatherProvider.notifier).fetchWeather();
            },
            child: const Text('もう一度試す'),
          ),
        ],
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
          Text(
            '${weatherDay.temperature.round()}°C',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(width: 8),
          // Text(
          //   _getJapaneseWeatherCondition(weatherDay.condition),
          //   style: TextStyle(
          //     fontSize: 18,
          //     color: color,
          //   ),
          // ),
          // const SizedBox(width: 8),
          Text(
            '${(weatherDay.precipProbability * 100).round()}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
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
