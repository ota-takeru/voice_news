import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NewsService {
  static const String _apiUrl = 'https://news-provider-api.vercel.app/news';
  static const String _lastFetchTimeKey = 'lastFetchTime';
  static const String _newsDataKey = 'newsData';
  static const int _maxStoredNews = 50; // 保存するニュース数の上限
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  Future<List<Map<String, dynamic>>> fetchNews() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchTime = prefs.getInt(_lastFetchTimeKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (currentTime - lastFetchTime > _cacheValidityDuration.inMilliseconds) {
      try {
        return await _fetchFromApi(prefs, currentTime);
      } catch (e) {
        print('APIからのデータ取得に失敗しました: $e');
        // APIからの取得に失敗した場合、ローカルデータを使用
        final localData = await _fetchFromLocal(prefs);
        if (localData.isEmpty) {
          // ローカルデータが空の場合、再度APIからの取得を試みる
          return await _fetchFromApi(prefs, currentTime);
        }
        return localData;
      }
    } else {
      final localData = await _fetchFromLocal(prefs);
      if (localData.isEmpty) {
        // ローカルデータが空の場合、APIからの取得を試みる
        return await _fetchFromApi(prefs, currentTime);
      }
      return localData;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFromApi(
      SharedPreferences prefs, int currentTime) async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      // print('API Response Status Code: ${response.statusCode}');
      // print('API Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> newData = json.decode(response.body);
        if (newData.isEmpty) {
          print('Warning: API returned empty data');
          return [];
        }
        await _storeNews(newData, prefs, currentTime);
        return List<Map<String, dynamic>>.from(newData);
      } else {
        print('Error: API returned status code ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching from API: $e');
      return [];
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
    print('Stored Data: $storedData');
    if (storedData != null) {
      final decodedData =
          List<Map<String, dynamic>>.from(json.decode(storedData));
      print('Decoded Stored Data: $decodedData');
      return decodedData;
    } else {
      print('No stored data found');
      return [];
    }
  }
}
