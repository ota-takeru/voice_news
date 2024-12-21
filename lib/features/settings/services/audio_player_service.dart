import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioPlayersServiceProvider =
    Provider<AudioPlayersService>((ref) => AudioPlayersService());

class AudioPlayersService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get audioPlayer => _audioPlayer;

  // 再生
  Future<void> play(String path) async {
    await _audioPlayer.play(DeviceFileSource(path));
  }

  // 一時停止
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  // 停止
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  // 再生位置
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;

  // 再生状態
  Stream<PlayerState> get playerStateStream =>
      _audioPlayer.onPlayerStateChanged;

  // 音量設定
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  // 再開
  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  // リソース解放
  void dispose() {
    _audioPlayer.dispose();
  }
}
