import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_item_model.dart';
import '../services/news_service.dart';

final newsServiceProvider = Provider((ref) => NewsService());

final newsProvider = StateNotifierProvider.family<NewsNotifier,
    AsyncValue<List<NewsItem>>, String?>((ref, keyword) {
  final newsService = ref.watch(newsServiceProvider);
  print("newsProviderが呼ばれた keyword: $keyword"); // この行を追加

  return NewsNotifier(newsService, keyword);
});

class NewsNotifier extends StateNotifier<AsyncValue<List<NewsItem>>> {
  final NewsService _newsService;
  final String? keyword; // キーワードを保持

  NewsNotifier(this._newsService, this.keyword)
      : super(const AsyncValue.loading()) {
    fetchNews(keyword); // 初期化時にキーワードを使ってニュースを取得
  }

  Future<void> fetchNews([String? keyword]) async {
    state = const AsyncValue.loading();
    try {
      final response = await _newsService.fetchNews(keyword);
      final news = response.map((item) => NewsItem.fromMap(item)).toList();
      state = AsyncValue.data(news);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
