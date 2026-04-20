import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  AudioManager._();
  static final instance = AudioManager._();

  AudioPlayer? _currentPlayer;
  String?      _currentPostId;

  Future<void> play({
    required String      postId,
    required String      previewUrl,
    required AudioPlayer player,
  }) async {
    // ✅ Stopper l'autre player si différent
    if (_currentPostId != null &&
        _currentPostId != postId) {
      await _currentPlayer?.pause();
      debugPrint(
          '⏹ Stop: $_currentPostId');
    }

    _currentPlayer = player;
    _currentPostId = postId;

    // ✅ Jouer directement sans recharger
    // si déjà chargé et pas completed
    if (player.processingState ==
            ProcessingState.ready ||
        player.processingState ==
            ProcessingState.buffering) {
      await player.play();
    } else if (player.processingState ==
        ProcessingState.completed) {
      // ✅ Reprendre depuis le début
      await player.seek(Duration.zero);
      await player.play();
    } else {
      // ✅ Charger puis jouer
      try {
        await player.setUrl(previewUrl);
        await player.play();
      } catch (e) {
        debugPrint(
            '❌ AudioManager play: $e');
      }
    }

    debugPrint('▶ Play: $postId');
  }

  Future<void> stop(String postId) async {
    if (_currentPostId == postId) {
      await _currentPlayer?.pause();
      _currentPostId = null;
      _currentPlayer = null;
    }
  }

  Future<void> stopAll() async {
    await _currentPlayer?.pause();
    _currentPostId = null;
    _currentPlayer = null;
  }
}
