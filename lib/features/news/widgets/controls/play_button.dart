import 'package:flutter/material.dart';
import '../../../../themes/app_colors.dart';

class PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final bool isContentVisible;

  const PlayButton({
    super.key,
    required this.isPlaying,
    required this.onPlay,
    required this.onPause,
    required this.isContentVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isPlaying ? '音声の再生を停止' : '音声を再生',
      button: true,
      child: ElevatedButton(
        onPressed: () {
          if (isPlaying) {
            onPause();
          } else {
            onPlay();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isPlaying ? AppColors.secondary : AppColors.primary,
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
            Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 40),
            const SizedBox(width: 8),
            Text(isPlaying ? '停止' : '再生',
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
