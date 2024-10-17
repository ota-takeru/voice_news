import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../controller/news_screen_controller.dart';
import '../models/news_item_model.dart';
import '../services/news_service.dart';

final newsServiceProvider = Provider((ref) => NewsService());

final newsProvider =
    StateNotifierProvider<NewsNotifier, AsyncValue<List<NewsItem>>>((ref) {
  final newsService = ref.watch(newsServiceProvider);
  return NewsNotifier(newsService);
});

class NewsNotifier extends StateNotifier<AsyncValue<List<NewsItem>>> {
  final NewsService _newsService;

  NewsNotifier(this._newsService) : super(const AsyncValue.loading()) {
    fetchNews();
  }

  Future<void> fetchNews() async {
    state = const AsyncValue.loading();
    try {
      final response = await _newsService.fetchNews();
      print('API Response: $response'); // デバッグログ
      if (response.isEmpty) {
        print('警告: 空のニュースデータを受信しました'); // 警告ログ
      }
      List<NewsItem> news = response.map((item) => NewsItem.fromMap(item)).toList();
      state = AsyncValue.data(news);
    } catch (e, stackTrace) {
      print('ニュース取得エラー: $e'); // エラーログ
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// final newsScreenControllerProvider =
//     Provider((ref) => NewsScreenController(ref));
