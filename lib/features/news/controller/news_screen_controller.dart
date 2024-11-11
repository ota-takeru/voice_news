import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_state_model.dart';
import '../providers/news_provider.dart';
import '../../settings/services/audioStreamingServices.dart';

final newsScreenControllerProvider =
    StateNotifierProvider<NewsScreenController, NewsState>((ref) {
  return NewsScreenController(ref);
});

class NewsScreenController extends StateNotifier<NewsState> {
  NewsScreenController(this._ref) : super(NewsState(news: [])) {
    _scrollController = ScrollController();
    _audioStreamingService = _ref.watch(audioStreamingServiceProvider);
    _initializeNews();
  }

  final Ref _ref;
  late final ScrollController _scrollController;
  late final AudioStreamingService _audioStreamingService;

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
      await _audioStreamingService
          .play(state.news[state.currentIndex].audioUrl ?? "");
      print("url ${state.news[state.currentIndex].audioUrl}");
    } catch (e) {
      print("Error playing content: $e");
      state = state.copyWith(isSpeaking: false, isReadingContent: false);
    }
  }

  Future<void> reStartSpeaking() async {
    await _audioStreamingService.reStart();
    state = state.copyWith(isSpeaking: true);
  }

  Future<void> pauseSpeaking() async {
    await _audioStreamingService.pause();
    state = state.copyWith(isSpeaking: false);
  }

  Future<void> nextNews() async {
    if (state.currentIndex < state.news.length - 1) {
      await _smoothScrollToTop();
      await _audioStreamingService.stop();
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isContentVisible: false,
        isSpeaking: false,
        isReadingContent: false,
      );
      await speakContent();
    }
  }

  Future<void> previousNews() async {
    if (state.currentIndex > 0) {
      await _smoothScrollToTop();
      await _audioStreamingService.stop();
      state = state.copyWith(
        currentIndex: state.currentIndex - 1,
        isContentVisible: false,
        isSpeaking: false,
        isReadingContent: false,
      );
      await speakContent();
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
    _audioStreamingService.stop();
    super.dispose();
  }
}
