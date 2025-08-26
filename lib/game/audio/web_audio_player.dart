import 'dart:async';
import '../utils/game_logger.dart';

// Fallback web audio implementation using simple logging
// Note: Real Web Audio API implementation would require package:web
class WebAudioPlayer {
  static final WebAudioPlayer _instance = WebAudioPlayer._internal();
  factory WebAudioPlayer() => _instance;
  WebAudioPlayer._internal() {
    gameLogger.initialize();
    _logger = gameLogger.audio;
  }

  Timer? _currentSoundTimer;
  late final GameCategoryLogger _logger;

  // Fallback implementation - logs audio instead of playing
  bool get audioContext => true;

  // Generate and play a beep tone
  Future<void> playBeep({
    double frequency = 800.0,
    int durationMs = 200,
    double volume = 0.3,
  }) async {
    try {
      // Stop any current sound
      _currentSoundTimer?.cancel();
      
      // Fallback to console logging
      _logger.info('🔊 BEEP: ${frequency.toInt()}Hz for ${durationMs}ms (Volume: ${(volume * 100).toInt()}%)');
      
    } catch (e) {
      _logger.error('Audio error: $e');
      // Fallback to console logging
      _logger.info('🔊 BEEP: ${frequency.toInt()}Hz for ${durationMs}ms (Volume: ${(volume * 100).toInt()}%)');
    }
  }

  void playCollisionSound() {
    // Low frequency thud
    playBeep(frequency: 200.0, durationMs: 150, volume: 0.4);
  }

  void playPickupSound() {
    // Pleasant ascending chime
    playBeep(frequency: 800.0, durationMs: 100, volume: 0.3);
    Timer(Duration(milliseconds: 120), () {
      playBeep(frequency: 1200.0, durationMs: 200, volume: 0.25);
    });
  }

  void playDoorOpenSound() {
    // Creaking door sequence
    playBeep(frequency: 300.0, durationMs: 200, volume: 0.4);
    Timer(Duration(milliseconds: 250), () {
      playBeep(frequency: 250.0, durationMs: 300, volume: 0.3);
    });
  }

  void playLevelCompleteSound() {
    // Success chord progression
    playBeep(frequency: 523.0, durationMs: 200, volume: 0.3); // C
    Timer(Duration(milliseconds: 250), () {
      playBeep(frequency: 659.0, durationMs: 200, volume: 0.3); // E
    });
    Timer(Duration(milliseconds: 500), () {
      playBeep(frequency: 784.0, durationMs: 400, volume: 0.4); // G
    });
  }

  void playMenuSelectSound() {
    // UI click sound
    playBeep(frequency: 1000.0, durationMs: 80, volume: 0.2);
  }

  void playAmbientDrip() {
    // Soft water drip
    playBeep(frequency: 2500.0, durationMs: 30, volume: 0.15);
  }

  void stop() {
    _currentSoundTimer?.cancel();
  }

  void dispose() {
    _currentSoundTimer?.cancel();
  }
}