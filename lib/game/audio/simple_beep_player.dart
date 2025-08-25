import 'package:flutter/services.dart';
import 'dart:async';

class SimpleBeepPlayer {
  static final SimpleBeepPlayer _instance = SimpleBeepPlayer._internal();
  factory SimpleBeepPlayer() => _instance;
  SimpleBeepPlayer._internal();

  Timer? _soundTimer;
  bool _isEnabled = false;

  // Enable audio by triggering a system sound first (requires user interaction)
  Future<void> enable() async {
    if (_isEnabled) return;
    
    try {
      // Try to play a system sound to enable audio context
      await SystemSound.play(SystemSoundType.click);
      _isEnabled = true;
      print('✅ Audio enabled! You should now hear sounds.');
    } catch (e) {
      print('⚠️ Audio enable failed: $e');
    }
  }

  Future<void> playBeep({
    required String name,
    SystemSoundType soundType = SystemSoundType.click,
    int durationMs = 200,
  }) async {
    try {
      if (!_isEnabled) {
        await enable();
      }
      
      // Play system sound
      await SystemSound.play(soundType);
      print('🔊 $name: System ${soundType.toString()} sound');
      
      // For web compatibility, also try HapticFeedback
      if (soundType == SystemSoundType.click) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
      
    } catch (e) {
      print('❌ Sound error for $name: $e');
    }
  }

  void playCollisionSound() {
    print('🔊 COLLISION: Wall hit');
    playBeep(
      name: 'Collision',
      soundType: SystemSoundType.click,
      durationMs: 150,
    );
  }

  void playPickupSound() {
    print('🔊 PICKUP: Item collected');
    playBeep(
      name: 'Pickup',
      soundType: SystemSoundType.alert,
      durationMs: 300,
    );
  }

  void playDoorOpenSound() {
    print('🔊 DOOR: Opening');
    playBeep(
      name: 'Door',
      soundType: SystemSoundType.alert,
      durationMs: 500,
    );
  }

  void playLevelCompleteSound() {
    print('🔊 SUCCESS: Level complete');
    playBeep(
      name: 'Success',
      soundType: SystemSoundType.alert,
      durationMs: 600,
    );
    // Play a second sound for fanfare effect
    Timer(Duration(milliseconds: 300), () {
      playBeep(
        name: 'Success 2',
        soundType: SystemSoundType.alert,
        durationMs: 400,
      );
    });
  }

  void playMenuSelectSound() {
    print('🔊 UI: Menu select');
    playBeep(
      name: 'Menu',
      soundType: SystemSoundType.click,
      durationMs: 100,
    );
  }

  void stop() {
    _soundTimer?.cancel();
  }

  void dispose() {
    _soundTimer?.cancel();
  }
}