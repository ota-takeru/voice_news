import 'dart:ui';

import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioStreamingServiceProvider =
    Provider<AudioStreamingService>((ref) => AudioStreamingService());

class AudioStreamingService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> play(String url) async {
     try {
    await _audioPlayer.setUrl(url);
    await _audioPlayer.play();
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> reStart() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }
  

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  void setCompletionCallback(VoidCallback callback) {
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        callback();
      }
    });
  }
}
