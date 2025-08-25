import 'package:flutter/services.dart';
import 'dart:async';

class SystemAudioPlayer {
  static final SystemAudioPlayer _instance = SystemAudioPlayer._internal();
  factory SystemAudioPlayer() => _instance;
  SystemAudioPlayer._internal();

  // Use system feedback for audio cues
  Future<void> playSystemFeedback(SystemSoundType sound) async {
    try {
      await SystemSound.play(sound);
    } catch (e) {
      print('System sound error: $e');
    }
  }

  void playCollisionSound() {
    print('🔊 COLLISION: Wall hit');
    // Use system click sound for collision
    playSystemFeedback(SystemSoundType.click);
  }

  void playPickupSound() {
    print('🔊 PICKUP: Item collected');
    // Use alert sound for pickup
    playSystemFeedback(SystemSoundType.alert);
  }

  void playDoorOpenSound() {
    print('🔊 DOOR: Opening');
    // Use alert for door opening
    playSystemFeedback(SystemSoundType.alert);
  }

  void playLevelCompleteSound() {
    print('🔊 SUCCESS: Level complete');
    // Use alert for success
    playSystemFeedback(SystemSoundType.alert);
  }

  void playMenuSelectSound() {
    print('🔊 UI: Menu select');
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