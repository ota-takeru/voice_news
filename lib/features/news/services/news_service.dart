import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NewsService {
  static const String _apiUrl = 'https://news-provider-api.vercel.app/news';
  static const String _lastFetchTimeKey = 'lastFetchTime';
  static const String _newsDataKey = 'newsData';
  static const int _maxStoredNews = 50; // 保存するニュース数の上限

  Future<List<Map<String, dynamic>>> fetchNews() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchTime = prefs.getInt(_lastFetchTimeKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (currentTime - lastFetchTime > 24 * 60 * 60 * 1000) {
      return _fetchFromApi(prefs, currentTime);
    } else {
      return _fetchFromLocal(prefs);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFromApi(
      SharedPreferences prefs, int currentTime) async {
    final response = await http.get(Uri.parse(_apiUrl));
    if (response.statusCode == 200) {
      final List<dynamic> newData = json.decode(response.body);
      await _storeNews(newData, prefs, currentTime);
      return List<Map<String, dynamic>>.from(newData);
    } else {
      throw Exception('Failed to load news');
    }
  }

  Future<void> _storeNews(
      List<dynamic> newData, SharedPreferences prefs, int currentTime) async {
    List<Map<String, dynamic>> storedNews = await _fetchFromLocal(prefs);

    // 新しいニュースを追加
    storedNews.insertAll(0, List<Map<String, dynamic>>.from(newData));

    // 上限を超えた古いニュースを削除
    if (storedNews.length > _maxStoredNews) {
      storedNews = storedNews.sublist(0, _maxStoredNews);
    }

    await prefs.setString(_newsDataKey, json.encode(storedNews));
    await prefs.setInt(_lastFetchTimeKey, currentTime);
  }

  Future<List<Map<String, dynamic>>> _fetchFromLocal(
      SharedPreferences prefs) async {
    final String? storedData = prefs.getString(_newsDataKey);
    if (storedData != null) {
      return List<Map<String, dynamic>>.from(json.decode(storedData));
    } else {
      return [];
    }
  }
}
