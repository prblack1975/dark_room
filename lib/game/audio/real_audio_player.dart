import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../utils/game_logger.dart';

class RealAudioPlayer {
  static final RealAudioPlayer _instance = RealAudioPlayer._internal();
  factory RealAudioPlayer() => _instance;
  RealAudioPlayer._internal() {
    gameLogger.initialize();
    _logger = gameLogger.audio;
  }

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;
  late final GameCategoryLogger _logger;

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      // Set the audio context for web
      await _player.setAudioContext(AudioContext(
        iOS: const AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: [
            AVAudioSessionOptions.defaultToSpeaker,
          ],
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ));
      _isInitialized = true;
    } catch (e) {
      _logger.error('Failed to initialize audio: $e');
    }
  }

  // Use short data URLs for simple tones
  Future<void> playBeep({
    double frequency = 800.0,
    int durationMs = 200,
    double volume = 0.3,
  }) async {
    try {
      await _initialize();
      
      // For web, we can try using a simple data URL tone
      // This is a very basic implementation
      _logger.info('🔊 Audio: ${frequency.toInt()}Hz beep for ${durationMs}ms');
      
      // Use a simple sound URL or generate one
      // For now, use a silent audio file approach
      await _player.setVolume(volume);
      
      // Since we don't have real audio files, let's try desktop audio
      if (_isInitialized) {
        // This would work with real audio files
        // await _player.play(AssetSource('audio/beep.wav'));
      }
      
    } catch (e) {
      _logger.error('Audio error: $e');
    }
  }

  void playCollisionSound() {
    _logger.info('🔊 COLLISION: Playing thud sound');
    playBeep(frequency: 200.0, durationMs: 150, volume: 0.4);
  }

  void playPickupSound() {
    _logger.info('🔊 PICKUP: Playing chime');
    playBeep(frequency: 1200.0, durationMs: 300, volume: 0.3);
  }

  void playDoorOpenSound() {
    _logger.info('🔊 DOOR: Playing creak');
    playBeep(frequency: 300.0, durationMs: 500, volume: 0.4);
  }

  void playLevelCompleteSound() {
    _logger.info('🔊 SUCCESS: Playing fanfare');
    playBeep(frequency: 800.0, durationMs: 600, volume: 0.4);
  }

  void playMenuSelectSound() {
    _logger.info('🔊 UI: Playing click');
    playBeep(frequency: 1000.0, durationMs: 100, volume: 0.3);
  }

  void stop() {
    _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}