import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_player_service.dart';
import 'tflite_service.dart';

class TTSService {
  final TfliteService _tfliteService = TfliteService();
  final AudioPlayersService _player;

  bool _isPlaying = false;
  bool _isPaused = false;
  List<String?> _audioPaths = [];
  int _currentIndex = 0;

  TTSService({
    required AudioPlayersService player,
  }) : _player = player;

  Future<void> initialize() async {
    // await _tfliteService.init();
  }

  Future<void> speak(String text) async {
    text = "hello world. this is sample text.";
    // 前回の再生を停止 
    await stop();

    try {
      // 文章を文単位で分割
      final sentences = text
          .split(RegExp(r'[。.!?！？]'))
          .where((s) => s.trim().isNotEmpty)
          .toList();


      _audioPaths = [];
      for (final sentence in sentences) {
        final audioPath = await _tfliteService.synthesize(sentence);
        _audioPaths.add(audioPath);
      }

      _currentIndex = 0;
      _isPlaying = true;
      _isPaused = false;

      // 波形を順次再生
      _playNextAudioPath();
    } catch (e) {
      print('Error in speak(): $e');
      _isPlaying = false;
      _isPaused = false;
    }
  }

  void _playNextAudioPath() {
    if (!_isPlaying || _isPaused || _currentIndex >= _audioPaths.length) {
      if (_currentIndex >= _audioPaths.length) {
        _isPlaying = false;
        _isPaused = false;
      }
      return;
    }

    final audioPath = _audioPaths[_currentIndex];
    if (audioPath == null) {
      _currentIndex++;
      _playNextAudioPath();
      return;
    }

    _player.play(audioPath).then((_) {
      if (_isPaused || !_isPlaying) {
        return;
      }
      // 再生が終わった波形を削除
      _audioPaths[_currentIndex] = null;
      _currentIndex++;
      _playNextAudioPath();
    }).catchError((error) {
      // エラーハンドリング
      _isPlaying = false;
      _isPaused = false;
      _currentIndex = 0;
      print('Error playing waveform: $error');
    });
  }

  void pause() {
    if (_isPlaying && !_isPaused) {
      _isPaused = true;
      _player.pause();
    }
  }

  Future<void> resume() async {
    if (_isPlaying && _isPaused) {
      _isPaused = false;
      await _player.resume();
    }
  }

  Future<void> stop() async {
    if (_isPlaying || _isPaused) {
      _isPlaying = false;
      _isPaused = false;
      _currentIndex = 0;
      await _player.stop();
    }
  }

  void dispose() {
    // _tfliteService.dispose();
    _player.dispose();
  }

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
}
 
final ttsServiceProvider = FutureProvider<TTSService>((ref) async {
  final player = ref.read(audioPlayersServiceProvider);
  final ttsService = TTSService(player: player);
  await ttsService.initialize();
  return ttsService;
});
