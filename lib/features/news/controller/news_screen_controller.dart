import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/services/tts_service.dart';
import '../models/news_state_model.dart';
import '../providers/news_provider.dart';
// import '../../settings/services/audioStreamingServices.dart';

final newsScreenControllerProvider =
    StateNotifierProvider<NewsScreenController, NewsState>((ref) {
  return NewsScreenController(ref);
});

class NewsScreenController extends StateNotifier<NewsState> {
  NewsScreenController(this._ref) : super(NewsState(news: [])) {
    _scrollController = ScrollController();
    // 非同期にTTSServiceを取得し、必要に応じて初期化
    _initializeNews();
  }

  final Ref _ref;
  late final ScrollController _scrollController;
  // late final AudioStreamingService _audioStreamingService;
  // TTSServiceを非同期に取得するためのFuture
  late final Future<TTSService> _ttsServiceFuture =
      _ref.read(ttsServiceProvider.future);

  ScrollController get scrollController => _scrollController;

  void _initializeNews() {
    final newsAsyncValue = _ref.read(newsProvider);
    newsAsyncValue.whenData((news) {
      state = state.copyWith(news: news);
    });
  }

  Future<void> speakContent() async {
    state = state.copyWith(isSpeaking: true, isReadingContent: true);
    try {
      final ttsService = await _ttsServiceFuture;
      // await ttsService.speak(state.news[state.currentIndex].content);
      await ttsService.speak("Hello, World!");
      print("url ${state.news[state.currentIndex].audioUrl}");
    } catch (e) {
      print("Error playing content: $e");
      state = state.copyWith(isSpeaking: false, isReadingContent: false);
    }
  }

  Future<void> reStartSpeaking() async {
    try {
      final ttsService = await _ttsServiceFuture;
      await ttsService.resume();
      state = state.copyWith(isSpeaking: true);
    } catch (e) {
      print("Error resuming speaking: $e");
    }
  }

  Future<void> pauseSpeaking() async {
    try {
      final ttsService = await _ttsServiceFuture;
      ttsService.pause();
      state = state.copyWith(isSpeaking: false);
    } catch (e) {
      print("Error pausing speaking: $e");
    }
  }

  Future<void> nextNews() async {
    if (state.currentIndex < state.news.length - 1) {
      await _smoothScrollToTop();
      try {
        final ttsService = await _ttsServiceFuture;
        await ttsService.stop();
        state = state.copyWith(
          currentIndex: state.currentIndex + 1,
          isContentVisible: false,
          isSpeaking: false,
          isReadingContent: false,
        );
        await speakContent();
      } catch (e) {
        print("Error moving to next news: $e");
      }
    }
  }

  Future<void> previousNews() async {
    if (state.currentIndex > 0) {
      await _smoothScrollToTop();
      try {
        final ttsService = await _ttsServiceFuture;
        await ttsService.stop();
        state = state.copyWith(
          currentIndex: state.currentIndex - 1,
          isContentVisible: false,
          isSpeaking: false,
          isReadingContent: false,
        );
        await speakContent();
      } catch (e) {
        print("Error moving to previous news: $e");
      }
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
    // disposeは非同期にできないため、stopを非同期に呼び出す
    _ttsServiceFuture.then((ttsService) => ttsService.stop()).catchError((e) {
      print("Error stopping TTSService during dispose: $e");
    });
    super.dispose();
  }
}
