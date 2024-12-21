import 'dart:ui';
import 'dart:typed_data';

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

  Future<void> playWaveForm(List<double> audioWaveform) async {
    Int16List int16Waveform = Int16List.fromList(
      audioWaveform
          .map((e) => (e * 32767).toInt().clamp(-32768, 32767))
          .toList(),
    );

    Uint8List byteData = int16Waveform.buffer.asUint8List();

    await _audioPlayer
        .setAudioSource(
      ConcatenatingAudioSource(
        children: [
          AudioSource.uri(
            Uri.dataFromBytes(byteData),
            tag: 'Audio from bytes',
          ),
        ],
      ),
    )
        .catchError((error) {
      print("Error loading audio source: $error");
      return null;
    });

    await _audioPlayer.play();
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

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  void setCompletionCallback(VoidCallback callback) {
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        callback();
      }
    });
  }
}
