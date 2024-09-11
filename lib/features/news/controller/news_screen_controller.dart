import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_state_model.dart';
import '../providers/news_provider.dart';
import '../../settings/services/flutter_tts_service.dart';

final newsScreenControllerProvider =
    StateNotifierProvider<NewsScreenController, NewsState>((ref) {
  return NewsScreenController(ref);
});

class NewsScreenController extends StateNotifier<NewsState> {
  NewsScreenController(this._ref) : super(NewsState(news: [])) {
    _scrollController = ScrollController();
    _initializeNews();
  }

  final Ref _ref;
  late final ScrollController _scrollController;

  ScrollController get scrollController => _scrollController;

  Future<void> _initializeNews() async {
    final newsAsyncValue = _ref.watch(newsProvider);
    newsAsyncValue.whenData((news) {
      state = state.copyWith(news: news);
    });
  }

  Future<void> speakTitle() async {
    final ttsService = _ref.read(flutterTtsServiceProvider);
    state = state.copyWith(isSpeaking: true, isReadingContent: false);
    await ttsService.speak(state.news[state.currentIndex].title);
  }

  Future<void> speakContent() async {
    final ttsService = _ref.read(flutterTtsServiceProvider);
    state = state.copyWith(isSpeaking: true, isReadingContent: true);
    await ttsService.speak(state.news[state.currentIndex].content);
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
