import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class NewsService {
  static const String _apiUrl = 'https://news-provider-api.vercel.app/getNews';
  static const String _lastFetchTimeKey = 'lastFetchTime';
  static const String _newsDataKey = 'newsData';
  static const int _maxStoredNews = 50;
  static const Duration _cacheValidityDuration = Duration(hours: 24);
  final Logger _logger = Logger();

  Future<List<Map<String, dynamic>>> fetchNews([String? keyword]) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(_lastFetchTimeKey) ?? 0);
    final cacheExpired =
        DateTime.now().difference(lastFetchTime) > _cacheValidityDuration;

    final localDataFuture = _fetchFromLocal(prefs, keyword);

    print("newsが呼ばれた $keyword");

    if (cacheExpired) {
      print("cache expired");
      try {
        return await _fetchFromApi(prefs, DateTime.now(), keyword);
      } catch (e) {
        _logger.w('APIからのデータ取得に失敗しました: $e');
        final localData = await localDataFuture;
        if (localData.isEmpty) {
          return []; // ローカルデータも空の場合、空リストを返す
        }
        return localData;
      }
    }

    final localData = await localDataFuture;
    // ローカルデータが空、またはキーワードがnullでない場合にキーワードに一致するニュースがない場合、APIから取得
    if (localData.isEmpty ||
        (keyword != null &&
            !localData.any((item) => item['keyword'] == keyword))) {
      try {
        return await _fetchFromApi(prefs, DateTime.now(), keyword);
      } catch (e) {
        _logger.w('APIからのデータ取得に失敗しました: $e');
      }
    }
    return localData;
  }

  Future<List<Map<String, dynamic>>> _fetchFromApi(
      SharedPreferences prefs, DateTime currentTime,
      [String? keyword]) async {
    // キーワードがnullでない場合はURLにキーワードパラメータを追加し、エンコードする
    final url = keyword != null
        ? Uri.parse('$_apiUrl')
            .replace(queryParameters: {'keyword': keyword}).toString()
        : _apiUrl;
    print("url $url");
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);

        if (responseBody is! List) {
          throw Exception('Unexpected response format');
        }

        final List<Map<String, dynamic>> processedData =
            responseBody.map((item) {
          final Map<String, dynamic> newsItem = Map<String, dynamic>.from(item);
          // APIレスポンスにキーワードが含まれていない場合のみ、キーワードを設定
          newsItem['keyword'] = newsItem['keyword'] ?? keyword ?? 'top';
          return newsItem;
        }).toList();

        if (processedData.isEmpty) {
          _logger.w('APIから取得したデータが空です');
        }

        await _storeNews(processedData, prefs, currentTime);
        return processedData;
      } else {
        throw Exception('API returned status code ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('APIからのデータ取得に失敗しました: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFromLocal(SharedPreferences prefs,
      [String? keyword]) async {
    final String? storedData = prefs.getString(_newsDataKey);
    if (storedData != null) {
      final List<dynamic> decodedData = json.decode(storedData);

      final List<Map<String, dynamic>> formattedData =
          decodedData.map((item) => Map<String, dynamic>.from(item)).toList();
      // キーワードによるフィルタリング: keywordがnullでない場合、keywordに一致する要素のみ抽出
      if (keyword != null) {
        return formattedData
            .where((item) =>
                item['keyword']?.toLowerCase() == keyword.toLowerCase())
            .toList();
      }
      // キーワードがnullの場合は、'top'キーワードのニュースを返す
      return formattedData.where((item) => item['keyword'] == 'top').toList();
    }
    return [];
  }

  Future<void> _storeNews(List<Map<String, dynamic>> newData,
      SharedPreferences prefs, DateTime currentTime) async {
    List<Map<String, dynamic>> storedNews = await _fetchFromLocal(prefs);
    storedNews.insertAll(0, newData);

    if (storedNews.length > _maxStoredNews) {
      storedNews = storedNews.sublist(0, _maxStoredNews);
    }
    await prefs.setString(_newsDataKey, json.encode(storedNews));
    await prefs.setInt(_lastFetchTimeKey, currentTime.millisecondsSinceEpoch);
  }
}
