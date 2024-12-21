import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NewsService {
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
        return await _fetchFromFunctions(prefs, currentTime);
      } catch (e) {
        print('Firebase Functionsからのデータ取得に失敗しました: $e');
        // Firebase Functionsからの取得に失敗した場合、ローカルデータを使用
        final localData = await _fetchFromLocal(prefs);
        if (localData.isEmpty) {
          // ローカルデータが空の場合、再度Firebase Functionsからの取得を試みる
          return await _fetchFromFunctions(prefs, currentTime);
        }
        return localData;
      }
    } else {
      final localData = await _fetchFromLocal(prefs);
      if (localData.isEmpty) {
        // ローカルデータが空の場合、Firebase Functionsからの取得を試みる
        return await _fetchFromFunctions(prefs, currentTime);
      }
      return localData;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFromFunctions(
      SharedPreferences prefs, int currentTime) async {
    // Firebase Functionsの呼び出し
    final functions = FirebaseFunctions.instanceFor(
        region: 'asia-northeast1'); // リージョンに合わせて変更
    final HttpsCallable callable = functions.httpsCallable('delivernews');
    try {
      final result = await callable();
      final data = result.data as Map<String, dynamic>;

      if (result.data != null) {
        final newData = (data['news'] as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        if (newData.isEmpty) {
          print('Warning: Firebase Functions returned empty data');
          return [];
        }
        await _storeNews(newData, prefs, currentTime);
        return newData;
      } else {
        print('Error: Firebase Functions returned null');
        return [];
      }
    } catch (e) {
      print('Error fetching from Firebase Functions: $e');
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
    if (storedData != null) {
      final decodedData =
          List<Map<String, dynamic>>.from(json.decode(storedData));
      // print('Decoded Stored Data: $decodedData');
      print('Stored data found');
      return decodedData;
    } else {
      print('No stored data found');
      return [];
    }
  }
}
