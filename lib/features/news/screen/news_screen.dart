import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/news_provider.dart';
import '../widgets/controls/navigation_button.dart';
import '../widgets/controls/play_button.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initTts();
      print("ttsの初期化が終了しました。");
      await ref.read(newsScreenControllerProvider).speakTitle();
      // final newsAsyncValue = ref.read(newsProvider);
      // newsAsyncValue.when(
      //   data: (_) =>
      //   error: (Object error, StackTrace stackTrace) {},
      //   loading: () {},
      // );
    });
  }

  Future<void> _initTts() async {
    try {
      await flutterTts.setLanguage("ja-JP");
      await flutterTts.setSpeechRate(0.7);
      flutterTts.setCompletionHandler(() {
        print("読み上げが終了");
        _handleTtsCompletion();
      });

      // エラーハンドリングを追加
      flutterTts.setErrorHandler((msg) {
        print("FlutterTts error: $msg");
      });

      print("ttsの初期化が完了");
    } catch (e) {
      print("FlutterTts initialization error: $e");
    }
  }

  void _handleTtsCompletion() {
    if (!mounted) return; // Stateが破棄されていないか確認

    setState(() {
      ref.read(isSpeakingProvider.notifier).state = false;
      if (!ref.read(isContentVisibleProvider)) {
        print("本文を表示する");
        _toggleContentVisibility();
      } else if (ref.read(isReadingContentProvider)) {
        ref.read(isReadingContentProvider.notifier).state = false;
        if (ref.read(currentIndexProvider) <
            ref.read(newsProvider).value!.length - 1) {
          nextNews();
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        print("Completion handler: Speaking content again");
        ref.read(newsScreenControllerProvider).speakContent();
      }
    });
  }

  void _toggleContentVisibility() {
    ref.read(isContentVisibleProvider.notifier).update((state) => !state);
    if (ref.read(isContentVisibleProvider) && !ref.read(isSpeakingProvider)) {
      ref.read(newsScreenControllerProvider).speakContent();
    }
  }

  void nextNews() {
    final newsData = ref.read(newsProvider).value!;
    if (ref.read(currentIndexProvider) < newsData.length - 1) {
      ref.read(currentIndexProvider.notifier).state++;
      ref.read(isContentVisibleProvider.notifier).state = false;
      ref.read(isSpeakingProvider.notifier).state = false;
      ref.read(isReadingContentProvider.notifier).state = false;
      flutterTts.stop();
      ref.read(newsScreenControllerProvider).speakTitle();
    } else {
      flutterTts.stop();
      ref.read(currentIndexProvider.notifier).state = 0; // インデックスをリセット
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void previousNews() {
    if (ref.read(currentIndexProvider) > 0) {
      ref.read(currentIndexProvider.notifier).state--;
      ref.read(isContentVisibleProvider.notifier).state = false;
      ref.read(isSpeakingProvider.notifier).state = false;
      ref.read(isReadingContentProvider.notifier).state = false;
      flutterTts.stop();
      ref.read(newsScreenControllerProvider).speakTitle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsAsyncValue = ref.watch(newsProvider);
    final currentIndex = ref.watch(currentIndexProvider);
    final isContentVisible = ref.watch(isContentVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('戻る'),
      ),
      body: newsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
        data: (newsData) => Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child:
                    _buildNewsContent(NewsItem.fromMap(newsData[currentIndex])),
              ),
            ),
            _buildActionButtons(),  
          ],
        ),
      ),
    );
  }

  Widget _buildNewsContent(NewsItem news) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            NewsTitle(
              title: news.title,
              onTap: _toggleContentVisibility,
            ),
            if (ref.watch(isContentVisibleProvider))
              NewsContent(content: news.content),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        PlayButton(
          tts: flutterTts,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NavigationButton(
              text: '前へ',
              onPressed: ref.read(currentIndexProvider) > 0
                  ? () {
                      HapticFeedback.lightImpact();
                      previousNews();
                    }
                  : null,
              style: ref.read(currentIndexProvider) > 0
                  ? ButtonStyles.prevButton(isActive: true)
                  : ButtonStyles.prevButton(isActive: false),
              icon: Icons.skip_previous,
              iconOnRight: false,
            ),
            const SizedBox(width: 60),
            NavigationButton(
              text: '次へ',
              onPressed: () {
                HapticFeedback.lightImpact();
                nextNews();
              },
              style: ButtonStyles.nextButton,
              icon: Icons.skip_next,
              iconOnRight: true,
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}

class NewsItem {
  final String title;
  final String content;

  NewsItem({required this.title, required this.content});

  factory NewsItem.fromMap(Map<String, dynamic> map) {
    return NewsItem(
      title: map['title'] ?? '不明なタイトル',
      content: map['content'] ?? '内容がありません',
    );
  }
}

class NewsTitle extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const NewsTitle({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class NewsContent extends StatelessWidget {
  final String content;

  const NewsContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        content,
        style: const TextStyle(fontSize: 18, height: 1.5),
      ),
    );
  }
}
