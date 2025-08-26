import 'package:flutter/services.dart';
import 'dart:async';
import '../utils/game_logger.dart';

class SystemAudioPlayer {
  static final SystemAudioPlayer _instance = SystemAudioPlayer._internal();
  factory SystemAudioPlayer() => _instance;
  SystemAudioPlayer._internal() {
    gameLogger.initialize();
    _logger = gameLogger.audio;
  }
  
  late final GameCategoryLogger _logger;

  // Use system feedback for audio cues
  Future<void> playSystemFeedback(SystemSoundType sound) async {
    try {
      await SystemSound.play(sound);
    } catch (e) {
      _logger.error('System sound error: $e');
    }
  }

  void playCollisionSound() {
    _logger.info('🔊 COLLISION: Wall hit');
    // Use system click sound for collision
    playSystemFeedback(SystemSoundType.click);
  }

  void playPickupSound() {
    _logger.info('🔊 PICKUP: Item collected');
    // Use alert sound for pickup
    playSystemFeedback(SystemSoundType.alert);
  }

  void playDoorOpenSound() {
    _logger.info('🔊 DOOR: Opening');
    // Use alert for door opening
    playSystemFeedback(SystemSoundType.alert);
  }

  void playLevelCompleteSound() {
    _logger.info('🔊 SUCCESS: Level complete');
    // Use alert for success
    playSystemFeedback(SystemSoundType.alert);
  }

  void playMenuSelectSound() {
    _logger.info('🔊 UI: Menu select');
    // Use click for UI
    playSystemFeedback(SystemSoundType.click);
  }

  void stop() {
    // System sounds stop automatically
  }

  void dispose() {
    // Nothing to dispose for system sounds
  }
}