import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_item_model.dart';
import '../models/news_state_model.dart';
import '../providers/news_provider.dart';
import '../../settings/services/flutter_tts_service.dart';

final newsScreenControllerProvider =
    StateNotifierProvider.family<NewsScreenController, NewsState, String?>(
        (ref, keyword) {
  return NewsScreenController(ref, keyword);
});

class NewsScreenController extends StateNotifier<NewsState> {
  NewsScreenController(this._ref, this._keyword) : super(NewsState(news: [])) {
    _scrollController = ScrollController();
    _initializeNews();
  }

  final Ref _ref;
  final String? _keyword;
  late final ScrollController _scrollController;

  ScrollController get scrollController => _scrollController;

  Future<void> _initializeNews() async {
    _ref.listen<AsyncValue<List<NewsItem>>>(
      newsProvider(_keyword),
      (previous, next) {
        next.whenData((news) {
          debugPrint('Received ${news.length} news items');
          state = state.copyWith(news: news);
        });
      },
      fireImmediately: true, // これで初期値も受け取れる
    );
  }

  Future<void> speakTitle() async {
    final ttsService = _ref.read(flutterTtsServiceProvider);
    // state.news が空でない、かつ currentIndex が有効な範囲内にあることを確認
    if (state.news.isNotEmpty &&
        state.currentIndex >= 0 &&
        state.currentIndex < state.news.length) {
      state = state.copyWith(isSpeaking: true, isReadingContent: false);
      await ttsService.speak(state.news[state.currentIndex].title);
    } else {
      // ニュースがない場合の処理。例えば、エラーメッセージを表示するなど。
      debugPrint('No news to speak.');
      // 必要であれば、ユーザーに通知するためのUI更新をここに追加
    }
  }

  Future<void> speakContent() async {
    final ttsService = _ref.read(flutterTtsServiceProvider);
    // こちらも同様に、state.newsが空でなく、currentIndexが有効範囲内か確認
    if (state.news.isNotEmpty &&
        state.currentIndex >= 0 &&
        state.currentIndex < state.news.length) {
      state = state.copyWith(isSpeaking: true, isReadingContent: true);
      await ttsService.speak(state.news[state.currentIndex].content);
    } else {
      debugPrint('No news content to speak.');
    }
  }

  Future<void> pauseSpeaking() async {
    final ttsService = _ref.read(flutterTtsServiceProvider);
    await ttsService.pause();
    state = state.copyWith(isSpeaking: false);
  }

  Future<void> nextNews() async {
    final ttsService = _ref.read(flutterTtsServiceProvider);
    if (state.currentIndex < state.news.length - 1) {
      await _smoothScrollToTop();
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isContentVisible: false,
        isSpeaking: false,
        isReadingContent: false,
      );
      await ttsService.stop();
      await speakTitle();
    }
  }

  Future<void> previousNews() async {
    final ttsService = _ref.read(flutterTtsServiceProvider);
    if (state.currentIndex > 0) {
      await _smoothScrollToTop();
      state = state.copyWith(
        currentIndex: state.currentIndex - 1,
        isContentVisible: false,
        isSpeaking: false,
        isReadingContent: false,
      );
      await ttsService.stop();
      await speakTitle();
    }
  }

  Future<void> _smoothScrollToTop() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 20),
        curve: Curves.easeOut,
      );
    }
  }

  void toggleContentVisibility() {
    state = state.copyWith(isContentVisible: !state.isContentVisible);
  }

  void handleTtsCompletion() {
    if (state.isReadingContent) {
      state = state.copyWith(isSpeaking: false, isReadingContent: false);
      if (state.currentIndex < state.news.length - 1) {
        nextNews();
      }
    } else {
      state = state.copyWith(
        isSpeaking: false,
        isContentVisible: true,
        isReadingContent: true,
      );
      speakContent();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
