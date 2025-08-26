import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import '../utils/game_logger.dart';

// Use audioplayers with generated tones for web compatibility
class FlutterAudioPlayer {
  static final FlutterAudioPlayer _instance = FlutterAudioPlayer._internal();
  factory FlutterAudioPlayer() => _instance;
  FlutterAudioPlayer._internal() {
    gameLogger.initialize();
    _logger = gameLogger.audio;
  }

  final AudioPlayer _player = AudioPlayer();
  Timer? _soundTimer;
  late final GameCategoryLogger _logger;

  // Generate a simple sine wave tone
  Uint8List generateTone(double frequency, int durationMs, double volume) {
    final sampleRate = 44100;
    final samples = (sampleRate * durationMs / 1000).round();
    final data = Uint8List(samples * 2); // 16-bit samples
    
    for (int i = 0; i < samples; i++) {
      final time = i / sampleRate;
      final value = (volume * 32767 * math.sin(2 * math.pi * frequency * time)).round();
      
      // Convert to 16-bit little-endian
      data[i * 2] = value & 0xFF;
      data[i * 2 + 1] = (value >> 8) & 0xFF;
    }
    
    return data;
  }

  Future<void> playTone({
    double frequency = 800.0,
    int durationMs = 200,
    double volume = 0.3,
  }) async {
    try {
      // For now, just provide audio feedback through console
      // In a full implementation, we would use the Web Audio API
      _logger.info('🔊 Playing ${frequency.toInt()}Hz for ${durationMs}ms at ${(volume * 100).toInt()}% volume');
      
      // Simulate sound duration
      _soundTimer?.cancel();
      _soundTimer = Timer(Duration(milliseconds: durationMs), () {
        // Sound finished
      });
      
    } catch (e) {
      _logger.error('Audio playback error: $e');
    }
  }

  void playCollisionSound() {
    _logger.info('🔊 COLLISION: Wall hit sound');
    playTone(frequency: 200.0, durationMs: 150, volume: 0.4);
  }

  void playPickupSound() {
    _logger.info('🔊 PICKUP: Item collected chime');
    playTone(frequency: 1200.0, durationMs: 300, volume: 0.3);
  }

  void playDoorOpenSound() {
    _logger.info('🔊 DOOR: Unlocking creak');
    playTone(frequency: 300.0, durationMs: 500, volume: 0.4);
  }

  void playLevelCompleteSound() {
    _logger.info('🔊 SUCCESS: Level completed fanfare');
    playTone(frequency: 800.0, durationMs: 200, volume: 0.4);
  }

  void playMenuSelectSound() {
    _logger.info('🔊 UI: Menu selection beep');
    playTone(frequency: 1000.0, durationMs: 100, volume: 0.3);
  }

  void stop() {
    _soundTimer?.cancel();
    _player.stop();
  }

  void dispose() {
    _soundTimer?.cancel();
    _player.dispose();
  }
}

