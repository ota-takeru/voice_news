import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  Future<Map<String, dynamic>> getLocationFromIP() async {
    final response = await http.get(Uri.parse('https://ipapi.co/json/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load location data');
    }
  }
}
