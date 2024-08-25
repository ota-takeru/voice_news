import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/weather_model.dart';

class WeatherService {
  final String apiKey;
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';

  WeatherService({required this.apiKey});

  Future<Weather> fetchWeatherForecast(
      {double? latitude, double? longitude}) async {
    if (latitude == null || longitude == null) {
      throw ArgumentError('Latitude and longitude must be provided');
    }

    final response = await http.get(Uri.parse(
        '$baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric'));

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);
      return Weather.fromJson(decodedResponse);
    } else if (response.statusCode >= 500) {
      throw Exception('Server error');
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
