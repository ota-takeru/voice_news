import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_provider.dart';
import 'news_screen.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newsProvider.notifier).fetchNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final newsState = ref.watch(newsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ニュースアプリ'),
      ),
      body: Center(
        child: newsState.when(
          data: (_) => ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NewsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            ),
            child: const Text('ニュースを読む',
                style: TextStyle(
                  fontSize: 24,
                )),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }
}