import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AssetAudioPlayer {
  static final AssetAudioPlayer _instance = AssetAudioPlayer._internal();
  factory AssetAudioPlayer() => _instance;
  AssetAudioPlayer._internal();

  final Map<String, AudioPlayer> _players = {};
  final List<AudioPlayer> _collisionPlayers = []; // Multiple collision sound players
  final Map<String, AudioPlayer> _continuousPlayers = {}; // Continuous looping sounds
  int _currentCollisionPlayer = 0;
  bool _isInitialized = false;

  Future<void> _initializePlayer(String soundName, String assetPath) async {
    if (_players.containsKey(soundName)) return;
    
    try {
      final player = AudioPlayer();
      // Preload the asset
      await player.setSource(AssetSource(assetPath));
      _players[soundName] = player;
      print('✅ Loaded audio: $soundName from $assetPath');
    } catch (e) {
      print('❌ Failed to load $soundName from $assetPath: $e');
      // Do not create backup player - this was causing clicking sounds
      // _players[soundName] = AudioPlayer();
    }
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    print('🔄 Initializing asset audio system...');
    
    // Initialize all sound players with asset paths
    await _initializePlayer('wall_hit', 'audio/interaction/wall-hit-cartoon.mp3');
    await _initializePlayer('pickup', 'audio/interaction/pickup.mp3');
    await _initializePlayer('door', 'audio/interaction/door.mp3');
    await _initializePlayer('success', 'audio/interaction/success.mp3');
    await _initializePlayer('click', 'audio/interaction/click.mp3');
    
    // Health-related sounds
    await _initializePlayer('damage', 'audio/interaction/wall-hit-cartoon.mp3'); // Reuse existing sound for damage
    await _initializePlayer('healing', 'audio/interaction/pickup.mp3'); // Reuse existing sound for healing
    await _initializePlayer('critical_health', 'audio/interaction/wall-hit-1-100717.mp3'); // Reuse for critical health warning
    await _initializePlayer('death', 'audio/interaction/wall-hit-1-100717.mp3'); // Reuse for death sound
    
    // Initialize multiple collision sound players for overlapping sounds
    for (int i = 0; i < 5; i++) {
      try {
        final player = AudioPlayer();
        await player.setSource(AssetSource('audio/interaction/wall-hit-cartoon.mp3'));
        _collisionPlayers.add(player);
        print('✅ Loaded collision player ${i + 1}');
      } catch (e) {
        print('❌ Failed to load collision player ${i + 1}: $e');
      }
    }
    
    _isInitialized = true;
    print('✅ Asset audio system ready!');
  }

  // Continuous sound methods
  Future<void> startContinuousSound(String soundName, String assetPath) async {
    try {
      await _initialize();
      
      // Don't recreate if already playing
      if (_continuousPlayers.containsKey(soundName)) {
        return;
      }
      
      final player = AudioPlayer();
      await player.setSource(AssetSource(assetPath));
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.0); // Start silent
      await player.resume(); // Start playing
      
      _continuousPlayers[soundName] = player;
      print('🔊 DEBUG: Started continuous audio playback for $soundName');
    } catch (e) {
      print('❌ Failed to start continuous sound $soundName: $e');
    }
  }

  Future<void> setContinuousSoundVolume(String soundName, double volume) async {
    try {
      final player = _continuousPlayers[soundName];
      if (player != null) {
        final clampedVolume = volume.clamp(0.0, 1.0);
        await player.setVolume(clampedVolume);
        print('🔊 DEBUG: Set $soundName volume to ${(clampedVolume * 100).toInt()}%');
      }
    } catch (e) {
      print('❌ Failed to set volume for $soundName: $e');
    }
  }

  void stopContinuousSound(String soundName) {
    try {
      final player = _continuousPlayers[soundName];
      if (player != null) {
        player.stop();
        player.dispose();
        _continuousPlayers.remove(soundName);
        print('🔊 DEBUG: Stopped continuous sound $soundName');
      }
    } catch (e) {
      print('❌ Failed to stop continuous sound $soundName: $e');
    }
  }

  Future<void> _playSound(String soundName, {double volume = 0.5}) async {
    try {
      await _initialize();
      
      final player = _players[soundName];
      if (player != null) {
        await player.setVolume(volume);
        await player.seek(Duration.zero);
        await player.resume();
        print('🔊 Playing: $soundName at ${(volume * 100).toInt()}% volume');
      } else {
        print('❌ Sound not found: $soundName (skipping playback)');
        return; // Exit early, don't try to play anything
      }
    } catch (e) {
      print('❌ Audio playback error for $soundName: $e');
      return; // Exit early on any error
    }
  }

  void playCollisionSound() {
    print('🔊 COLLISION: Wall hit');
    _playCollisionSoundOverlap();
  }
  
  Future<void> _playCollisionSoundOverlap() async {
    try {
      await _initialize();
      
      if (_collisionPlayers.isEmpty) {
        // Fallback to regular method if collision players failed to load
        _playSound('wall_hit', volume: 0.4);
        return;
      }
      
      // Use next available collision player for overlapping sounds
      final player = _collisionPlayers[_currentCollisionPlayer];
      _currentCollisionPlayer = (_currentCollisionPlayer + 1) % _collisionPlayers.length;
      
      await player.setVolume(0.4);
      await player.seek(Duration.zero);
      await player.resume();
      print('🔊 Playing collision sound on player $_currentCollisionPlayer');
    } catch (e) {
      print('❌ Collision sound error: $e');
    }
  }

  void playPickupSound() {
    print('🔊 PICKUP: Item collected');
    _playSound('pickup', volume: 0.3);
  }

  void playDoorOpenSound() {
    print('🔊 DOOR: Opening');
    _playSound('door', volume: 0.5);
  }

  void playLevelCompleteSound() {
    print('🔊 SUCCESS: Level complete');
    _playSound('success', volume: 0.6);
  }

  void playMenuSelectSound() {
    print('🔊 UI: Menu select (DISABLED - audio loading issue)');
    // _playSound('click', volume: 0.3); // Temporarily disabled due to audio loading issues
  }

  void playDamageSound({double volume = 0.5}) {
    print('🔊 HEALTH: Damage taken');
    _playSound('damage', volume: volume);
  }

  void playHealingSound({double volume = 0.6}) {
    print('🔊 HEALTH: Health restored');
    _playSound('healing', volume: volume);
  }

  void playCriticalHealthSound() {
    print('🔊 HEALTH: Critical health warning');
    _playSound('critical_health', volume: 0.8);
  }

  void playDeathSound() {
    print('🔊 HEALTH: Player death');
    _playSound('death', volume: 0.9);
  }

  void stop() {
    for (final player in _players.values) {
      player.stop();
    }
    for (final player in _collisionPlayers) {
      player.stop();
    }
    for (final player in _continuousPlayers.values) {
      player.stop();
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    
    for (final player in _collisionPlayers) {
      player.dispose();
    }
    _collisionPlayers.clear();
    
    for (final player in _continuousPlayers.values) {
      player.dispose();
    }
    _continuousPlayers.clear();
  }
}