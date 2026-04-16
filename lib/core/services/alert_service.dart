import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class AlertService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> startProviderAlertLoop() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/alert.mp3'));
    } catch (_) {}

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        await Vibration.vibrate(pattern: [0, 700, 500], repeat: 0);
      }
    } catch (_) {}
  }

  static Future<void> stopProviderAlertLoop() async {
    try {
      await _player.stop();
    } catch (_) {}

    try {
      await Vibration.cancel();
    } catch (_) {}
  }
}