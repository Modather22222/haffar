import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  SoundManager._();

  /// Single shared player — creating one player per sound leaks native
  /// resources until audio silently stops working.
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.resume(); // reset any completed/error state before replay
      await _player.play(AssetSource(asset));
    } catch (_) {
      // never crash the quiz over audio
    }
  }

  static Future<void> playCorrect([String id = 'default']) => _play('audio/correct.mp3');

  static Future<void> playWrong([String id = 'default']) => _play('audio/incorrect.mp3');

  static Future<void> dispose() => _player.dispose();
}
