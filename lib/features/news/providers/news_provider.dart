import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/news_screen_controller.dart';
import '../services/news_service.dart';

final newsServiceProvider = Provider((ref) => NewsService());

final newsProvider =
    StateNotifierProvider<NewsNotifier, AsyncValue<List<Map<String, dynamic>>>>(
        (ref) {
  final newsService = ref.watch(newsServiceProvider);
  return NewsNotifier(newsService);
});

class NewsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final NewsService _newsService;

  NewsNotifier(this._newsService) : super(const AsyncValue.loading());

  Future<void> fetchNews() async {
    state = const AsyncValue.loading();
    try {
      final news = await _newsService.fetchNews();
      state = AsyncValue.data(news);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final currentIndexProvider = StateProvider<int>((ref) => 0);

final isSpeakingProvider = StateProvider<bool>((ref) => false);

final isContentVisibleProvider = StateProvider<bool>((ref) => false);

final isReadingContentProvider = StateProvider<bool>((ref) => false);

final newsScreenControllerProvider =
    Provider((ref) => NewsScreenController(ref));
