import 'package:just_audio/just_audio.dart';

class SoundService {
  SoundService._();

  static final SoundService _instance = SoundService._();
  static SoundService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  bool get enabled => _enabled;
  void toggle() => _enabled = !_enabled;
  void enable() => _enabled = true;
  void disable() => _enabled = false;

  Future<void> _play(String asset) async {
    if (!_enabled) return;
    try {
      await _player.setAsset(asset);
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (_) {
      // Sound not critical — fail silently
    }
  }

  Future<void> tap() => _play('assets/sounds/tap.mp3');
  Future<void> select() => _play('assets/sounds/select.mp3');
  Future<void> success() => _play('assets/sounds/success.mp3');
  Future<void> booking() => _play('assets/sounds/booking.mp3');
  Future<void> error() => _play('assets/sounds/error.mp3');

  void dispose() => _player.dispose();
}
