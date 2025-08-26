import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../utils/game_logger.dart';

class WebRealAudioPlayer {
  static final WebRealAudioPlayer _instance = WebRealAudioPlayer._internal();
  factory WebRealAudioPlayer() => _instance;
  WebRealAudioPlayer._internal() {
    gameLogger.initialize();
    _logger = gameLogger.audio;
  }

  final Map<String, AudioPlayer> _players = {};
  bool _isInitialized = false;
  late final GameCategoryLogger _logger;

  // Simple audio data URLs (very short beeps)
  static const String _clickSound = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmMeByOU1PXSeSwGJ3nE8N2QQAoUXrTp66hVFApGn+DyvmMeByOU1PXSeSwGJ3nE8N2QQAoUXrTp66hVFAo=';
  
  static const String _alertSound = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmMeByOU1PXSeSwGJ3nE8N2QQAoUXrTp66hVFApGn+DyvmMeByOU1PXSeSwGJ3nE8N2QQAoUXrTp66hVFAo=';

  Future<void> _initializePlayer(String soundName, String dataUrl) async {
    if (_players.containsKey(soundName)) return;
    
    try {
      final player = AudioPlayer();
      await player.setSource(UrlSource(dataUrl));
      _players[soundName] = player;
      _logger.success('Initialized audio: $soundName');
    } catch (e) {
      _logger.error('Failed to initialize $soundName: $e');
    }
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    _logger.process('Initializing web audio system...');
    
    // Initialize all sound players
    await _initializePlayer('click', _clickSound);
    await _initializePlayer('alert', _alertSound);
    
    _isInitialized = true;
    _logger.success('Web audio system ready!');
  }

  Future<void> _playSound(String soundName, {double volume = 0.5}) async {
    try {
      await _initialize();
      
      final player = _players[soundName];
      if (player != null) {
        await player.setVolume(volume);
        await player.seek(Duration.zero);
        await player.resume();
        _logger.info('🔊 Playing: $soundName at ${(volume * 100).toInt()}% volume');
      } else {
        _logger.error('Sound not found: $soundName');
      }
    } catch (e) {
      _logger.error('Audio error: $e');
    }
  }

  void playCollisionSound() {
    _logger.info('🔊 COLLISION: Wall hit');
    _playSound('click', volume: 0.4);
  }

  void playPickupSound() {
    _logger.info('🔊 PICKUP: Item collected');
    _playSound('alert', volume: 0.3);
  }

  void playDoorOpenSound() {
    _logger.info('🔊 DOOR: Opening');
    _playSound('alert', volume: 0.5);
  }

  void playLevelCompleteSound() {
    _logger.info('🔊 SUCCESS: Level complete');
    _playSound('alert', volume: 0.6);
  }

  void playMenuSelectSound() {
    _logger.info('🔊 UI: Menu select');
    _playSound('click', volume: 0.3);
  }

  void stop() {
    for (final player in _players.values) {
      player.stop();
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}