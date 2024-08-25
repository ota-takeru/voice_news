import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

final newsScreenControllerProvider =
    Provider((ref) => NewsScreenController(ref));

class NewsScreenController {
  NewsScreenController(this._ref);

  final ProviderRef _ref;
  final FlutterTts flutterTts = FlutterTts();

  Future<void> speakTitle() async {
    final newsData = _ref.read(newsProvider).value!;
    final currentIndex = _ref.read(currentIndexProvider);
    _ref.read(isSpeakingProvider.notifier).state = true;
    _ref.read(isReadingContentProvider.notifier).state = false;
    await flutterTts.speak(newsData[currentIndex]['title'] ?? '不明なタイトル');
  }

  Future<void> speakContent() async {
    final newsData = _ref.read(newsProvider).value!;
    final currentIndex = _ref.read(currentIndexProvider);
    _ref.read(isSpeakingProvider.notifier).state = true;
    _ref.read(isReadingContentProvider.notifier).state = true;
    await flutterTts.speak(newsData[currentIndex]['content'] ?? '内容がありません');
  }
}
