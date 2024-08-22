import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../themes/app_colors.dart';
import '../providers/news_provider.dart';

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
    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakTitle();
    });
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("ja-JP");
    await flutterTts.setSpeechRate(0.7);
    flutterTts.setCompletionHandler(() {
      _handleTtsCompletion();
    });
  }

  void _handleTtsCompletion() {
    ref.read(isSpeakingProvider.notifier).state = false;
    if (!ref.read(isContentVisibleProvider)) {
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
      _speakContent();
    }
  }

  Future<void> _speakTitle() async {
    final newsData = ref.read(newsProvider).value!;
    final currentIndex = ref.read(currentIndexProvider);
    ref.read(isSpeakingProvider.notifier).state = true;
    ref.read(isReadingContentProvider.notifier).state = false;
    await flutterTts.speak(newsData[currentIndex]['title'] ?? '不明なタイトル');
  }

  Future<void> _speakContent() async {
    final newsData = ref.read(newsProvider).value!;
    final currentIndex = ref.read(currentIndexProvider);
    ref.read(isSpeakingProvider.notifier).state = true;
    ref.read(isReadingContentProvider.notifier).state = true;
    await flutterTts.speak(newsData[currentIndex]['content'] ?? '内容がありません');
  }

  void _toggleContentVisibility() {
    ref.read(isContentVisibleProvider.notifier).update((state) => !state);
    if (ref.read(isContentVisibleProvider) && !ref.read(isSpeakingProvider)) {
      _speakContent();
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
      _speakTitle();
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
      _speakTitle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsAsyncValue = ref.watch(newsProvider);
    final currentIndex = ref.watch(currentIndexProvider);
    final isContentVisible = ref.watch(isContentVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ニュース'),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomButton(
              text: '< 前へ',
              onPressed: ref.read(currentIndexProvider) > 0
                  ? () {
                      HapticFeedback.lightImpact();
                      previousNews();
                    }
                  : null,
              style: ref.read(currentIndexProvider) > 0
                  ? ButtonStyles.prevButton(isActive: true)
                  : ButtonStyles.prevButton(isActive: false),
            ),
            const SizedBox(width: 20),
            CustomButton(
              text: '次へ >',
              onPressed: () {
                HapticFeedback.lightImpact();
                nextNews();
              },
              style: ButtonStyles.nextButton,
            ),
          ],
        ),
        const SizedBox(height: 60),
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

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle style;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: onPressed == null
          ? style.copyWith(
              backgroundColor: WidgetStateProperty.all(AppColors.background),
              foregroundColor: WidgetStateProperty.all(AppColors.disabled),
            )
          : style,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: onPressed == null ? AppColors.disabled : null,
        ),
      ),
    );
  }
}

class ButtonStyles {
  static final ButtonStyle nextButton = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    minimumSize: const Size(150, 60),
  );

  static ButtonStyle prevButton({required bool isActive}) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      minimumSize: const Size(150, 60),
      backgroundColor: isActive ? AppColors.secondary : AppColors.background,
      foregroundColor: isActive ? Colors.white : AppColors.disabled,
      side: BorderSide(
          color: isActive ? AppColors.primary : AppColors.disabled, width: 4),
    ).copyWith(
      elevation: WidgetStateProperty.all(0),
    );
  }
}
