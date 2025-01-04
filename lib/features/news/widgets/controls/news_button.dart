import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/news_provider.dart';
import '../../screen/news_screen.dart';

/// Riverpod での ConsumerWidget を利用
/// [keyword] が null ならデフォルトのニュース画面、
/// そうでなければキーワード付きのニュース画面へ遷移
class NewsButton extends ConsumerWidget {
  final String? keyword;

  const NewsButton({
    super.key,
    this.keyword,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ニュースを監視する (AsyncValue<List<String>>)
    final newsState = ref.watch(newsProvider);

    // newsState.when: (data / loading / error) のいずれかに応じてウィジェットを返す
    return newsState.when(
      data: (newsData) {
        // 例: 受け取ったニュースリストが空ならボタンを出さずメッセージ表示
        if (newsData.isEmpty) {
          return const Text('現在ニュースはありません');
        }

        // ボタン表示（デフォルトかキーワード付きかを切り替える）
        return Semantics(
          label: 'ニュースを読むボタン',
          button: true,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => keyword == null
                      ? const NewsScreen()
                      : NewsScreen(keyword: keyword!),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.volume_up, size: 22),
            label: Text(
              keyword == null ? 'ニュースを読む' : '$keyword',
              style: const TextStyle(fontSize: 22),
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text('エラーが発生しました: $error'),
    );
  }
}
