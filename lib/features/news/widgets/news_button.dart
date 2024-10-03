import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screen/news_screen.dart';
import '../providers/news_provider.dart';

class NewsButton extends ConsumerWidget {
  const NewsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsState = ref.watch(newsProvider);

    return newsState.when(
      data: (newsData) {
        if (newsData.isEmpty) {
          return const Text('現在ニュースを取得できません');
        }
        return Semantics(
          label: 'ニュースを読むボタン',
          button: true,
          child: ElevatedButton(
            onPressed: () => _navigateToNewsScreen(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'ニュースを読む',
              style: TextStyle(fontSize: 22),
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('エラーが発生しました: $error'),
    );
  }

  void _navigateToNewsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NewsScreen()),
    );
  }
}
