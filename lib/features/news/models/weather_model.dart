class Weather {
  final WeatherDay today;
  final WeatherDay tomorrow;
  final String cityName;

  Weather({
    required this.today,
    required this.tomorrow,
    required this.cityName,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final List<dynamic> list = json['list'];
    final todayData = list[0];
    final tomorrowData = list.firstWhere((item) =>
        DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000).day !=
        DateTime.fromMillisecondsSinceEpoch(todayData['dt'] * 1000).day);

    return Weather(
      today: WeatherDay.fromJson(todayData),
      tomorrow: WeatherDay.fromJson(tomorrowData),
      cityName: json['city']['name'],
    );
  }
}

class WeatherDay {
  final double temperature;
  final String condition;

  WeatherDay({
    required this.temperature,
    required this.condition,
  });

  factory WeatherDay.fromJson(Map<String, dynamic> json) {
    return WeatherDay(
      temperature: json['main']['temp'].toDouble(),
      condition: json['weather'][0]['main'],
    );
  }
}
