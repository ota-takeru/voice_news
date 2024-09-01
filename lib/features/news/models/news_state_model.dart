import 'news_item_model.dart';

class NewsState {
  final List<NewsItem> news;
  final int currentIndex;
  final bool isSpeaking;
  final bool isContentVisible;
  final bool isReadingContent;
  final bool shouldResetScroll;

  NewsState({
    required this.news,
    this.currentIndex = 0,
    this.isSpeaking = false,
    this.isContentVisible = false,
    this.isReadingContent = false,
    this.shouldResetScroll = false,
  });

  NewsState copyWith({
    List<NewsItem>? news,
    int? currentIndex,
    bool? isSpeaking,
    bool? isContentVisible,
    bool? isReadingContent,
    bool? shouldResetScroll,
  }) {
    return NewsState(
        news: news ?? this.news,
        currentIndex: currentIndex ?? this.currentIndex,
        isSpeaking: isSpeaking ?? this.isSpeaking,
        isContentVisible: isContentVisible ?? this.isContentVisible,
        isReadingContent: isReadingContent ?? this.isReadingContent,
        shouldResetScroll: shouldResetScroll ?? this.shouldResetScroll);
  }
}
