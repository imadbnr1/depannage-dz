import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';

class AlertService {
  static final AudioPlayer _player = AudioPlayer();
  static final AudioPlayer _popupPlayer = AudioPlayer();
  static Timer? _providerLoopGuard;
  static bool _providerLoopActive = false;

  static Future<void> startProviderAlertLoop() async {
    _providerLoopActive = true;
    _providerLoopGuard?.cancel();
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/alert.mp3'));
    } catch (_) {}

    _providerLoopGuard = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!_providerLoopActive) return;
      try {
        final state = _player.state;
        if (state != PlayerState.playing) {
          await _player.setReleaseMode(ReleaseMode.loop);
          await _player.play(AssetSource('sounds/alert.mp3'));
        }
      } catch (_) {}
    });

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        await Vibration.vibrate(pattern: [0, 700, 500], repeat: 0);
      }
    } catch (_) {}
  }

  static Future<void> stopProviderAlertLoop() async {
    _providerLoopActive = false;
    _providerLoopGuard?.cancel();
    _providerLoopGuard = null;
    try {
      await _player.stop();
    } catch (_) {}

    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  static Future<void> playAdminPopupAlert() async {
    try {
      await _popupPlayer.stop();
      await _popupPlayer.setReleaseMode(ReleaseMode.stop);
      await _popupPlayer.setVolume(1.0);
      await _popupPlayer.play(AssetSource('sounds/admin_popup.ogg'));
    } catch (_) {}

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        await Vibration.vibrate(duration: 220);
      }
    } catch (_) {}
  }
}
