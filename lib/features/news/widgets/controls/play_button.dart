import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../themes/app_colors.dart';
import '../../providers/news_provider.dart';

class PlayButton extends ConsumerWidget {
  const PlayButton({
    super.key,
    required this.tts,
  });

  final FlutterTts tts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSpeaking = ref.watch(isSpeakingProvider);
    return Semantics(
      label: isSpeaking ? '音声の再生を停止' : '音声を再生',
      button: true,
      child: ElevatedButton(
        onPressed: () async {
          if (isSpeaking) {
            await tts.pause();
            ref.read(isSpeakingProvider.notifier).state = false;
          } else {
            if (ref.read(isContentVisibleProvider)) {
              ref
                  .read(newsScreenControllerProvider)
                  .speakContent(); // Provider経由で呼び出す
            } else {
              ref
                  .read(newsScreenControllerProvider)
                  .speakTitle(); // Provider経由で呼び出す
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSpeaking ? AppColors.secondary : AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          minimumSize: const Size(100, 40),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSpeaking ? Icons.pause : Icons.play_arrow, size: 40), // 追加
            const SizedBox(width: 8), // 追加
            Text(isSpeaking ? '停止' : '再生',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
