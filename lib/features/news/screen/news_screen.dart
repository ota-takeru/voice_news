import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voice_news/themes/app_colors.dart';
import '../../settings/services/flutter_tts_service.dart';
import '../controller/news_screen_controller.dart';
import '../models/news_item_model.dart';
import '../models/news_state_model.dart';
// import '../providers/news_provider.dart';
import '../widgets/controls/navigation_button.dart';
import '../widgets/controls/play_button.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  late ScrollController _scrollController;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _scrollController =
        ref.read(newsScreenControllerProvider.notifier).scrollController;
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final ttsService = ref.read(flutterTtsServiceProvider);
    await ttsService.loadVoiceSettings();
    ttsService.setCompletionCallback(() {
      if (_mounted) {
        ref.read(newsScreenControllerProvider.notifier).handleTtsCompletion();
      }
    });
    if (_mounted) {
      await ref.read(newsScreenControllerProvider.notifier).speakTitle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsState = ref.watch(newsScreenControllerProvider);
    final controller = ref.read(newsScreenControllerProvider.notifier);
    ref.watch(flutterTtsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('戻る'),
      ),
      body: newsState.news.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: _buildNewsContent(
                        newsState.news[newsState.currentIndex]),
                  ),
                ),
                _buildActionButtons(controller, newsState),
              ],
            ),
    );
  }

  Widget _buildNewsContent(NewsItem news) {
    return Column(
      children: [
        NewsTitle(
          title: news.title,
          onTap: () => ref
              .read(newsScreenControllerProvider.notifier)
              .toggleContentVisibility(),
        ),
        NewsDateAndSource(
          publishedAt: news.publishedAt,
          sourceName: news.sourceName,
          sourceUrl: news.sourceUrl,
        ),
        NewsContent(content: news.content),
        NewsLinks(url: news.url),
      ],
    );
  }

  Widget _buildActionButtons(
      NewsScreenController controller, NewsState newsState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        PlayButton(
          isPlaying: newsState.isSpeaking,
          onPlay: newsState.isContentVisible
              ? controller.speakContent
              : controller.speakTitle,
          onPause: controller.pauseSpeaking,
          isContentVisible: newsState.isContentVisible,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NavigationButton(
              text: '前へ',
              onPressed: newsState.currentIndex > 0
                  ? () {
                      HapticFeedback.lightImpact();
                      controller.previousNews();
                    }
                  : null,
              style:
                  ButtonStyles.prevButton(isActive: newsState.currentIndex > 0),
              icon: Icons.skip_previous,
              iconOnRight: false,
            ),
            const SizedBox(width: 60),
            NavigationButton(
              text: '次へ',
              onPressed: newsState.currentIndex < newsState.news.length - 1
                  ? () {
                      HapticFeedback.lightImpact();
                      controller.nextNews();
                    }
                  : null,
              style: ButtonStyles.nextButton(
                  isActive: newsState.currentIndex < newsState.news.length - 1),
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
  void deactivate() {
    if (_mounted) {
      ref.read(flutterTtsServiceProvider).stop();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }
}

// NewsTitle
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

// NewsDateAndSource
class NewsDateAndSource extends StatelessWidget {
  final String? publishedAt;
  final String? sourceName;
  final String? sourceUrl;

  const NewsDateAndSource(
      {super.key, this.publishedAt, this.sourceName, this.sourceUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(width: 40),
        if (publishedAt != null)
          Text(
            publishedAt!.substring(0, 10),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
        const SizedBox(width: 20),
        if (sourceName != null && sourceUrl != null)
          GestureDetector(
            onTap: () async {
              final Uri url = Uri.parse(sourceUrl!);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: Text(
              sourceName!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.text,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }
}

// NewsContent
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

// NewsLinks
class NewsLinks extends StatelessWidget {
  final String? url;

  const NewsLinks({super.key, this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              final Uri url = Uri.parse(this.url!);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.link,
                  size: 16,
                  color: Colors.blue,
                ),
                SizedBox(width: 4),
                Text(
                  '記事リンク',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
