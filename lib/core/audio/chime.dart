import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// One-note confirmation blip for a selection: much of the audience cannot read yet, so a child who
/// cannot read "Search" still hears the press land. The asset is the reference's WebAudio tone: an E5
/// sine whose gain rises from 0.0001 to 0.05 in 12 ms and falls back by 260 ms, stopped at 280 ms.
abstract final class Chime {
  /// Off by default; DeviceGate turns it on for a paired TV. The console shares TvFocusable and stays silent.
  static bool enabled = false;

  /// What a chime does; tests count presses instead of reaching the platform.
  @visibleForTesting
  static VoidCallback sound = () => unawaited(_play());

  static Future<AudioPlayer>? _player;

  static void play() {
    if (enabled) sound();
  }

  // Built on first use, so a TV that never pairs never loads a player.
  static Future<AudioPlayer> _load() async {
    // A SoundPool sound never reports completion, so a position updater would schedule frames forever.
    final player = AudioPlayer()..positionUpdater = null;
    // No audio focus: taking it would pause the film or narration a press lands on.
    await player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource('sounds/chime.wav'));
    return player;
  }

  static Future<void> _play() async {
    try {
      final player = await (_player ??= _load());
      // A finished sound only replays from a stop.
      await player.stop();
      await player.resume();
    } on Exception catch (error) {
      // A set that cannot play the tone is no reason to lose the selection.
      debugPrint('Chime unavailable: $error');
    }
  }
}
