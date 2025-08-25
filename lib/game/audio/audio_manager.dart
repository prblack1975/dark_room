import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'dart:math' as math;
import '../components/wall.dart';
import '../utils/line_intersection.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final Map<String, AudioPlayer> _players = {};
  final Map<String, bool> _isLooping = {};
  final Map<String, bool> _isContinuousPlaying = {};
  final Map<String, double> _currentVolumes = {};
  
  // 3D audio parameters
  static const double maxAudioDistance = 200.0;
  static const double minVolume = 0.0;
  static const double maxVolume = 1.0;

  Future<void> preloadSound(String soundName, String assetPath, {bool loop = false}) async {
    try {
      final player = AudioPlayer();
      await player.setSource(AssetSource(assetPath));
      _players[soundName] = player;
      _isLooping[soundName] = loop;
      
      if (loop) {
        await player.setReleaseMode(ReleaseMode.loop);
      }
    } catch (e) {
      print('Failed to load audio: $soundName from $assetPath - $e');
      // For MVP, we'll continue without audio if files are missing
    }
  }

  Future<void> playSound(String soundName, {double volume = 1.0}) async {
    final player = _players[soundName];
    if (player != null) {
      await player.setVolume(volume.clamp(minVolume, maxVolume));
      await player.resume();
    }
  }

  Future<void> stopSound(String soundName) async {
    final player = _players[soundName];
    if (player != null) {
      await player.stop();
    }
  }

  void stopAllSounds() {
    for (final player in _players.values) {
      player.stop();
    }
  }

  // Calculate 3D audio parameters based on player and sound source positions
  AudioSpatialData calculate3DAudio(Vector2 playerPosition, Vector2 soundPosition, {double maxDistance = maxAudioDistance}) {
    final distance = playerPosition.distanceTo(soundPosition);
    
    // Calculate volume based on distance
    double volume = 1.0;
    if (distance > maxDistance) {
      volume = 0.0;
    } else if (distance > 0) {
      volume = (maxDistance - distance) / maxDistance;
      volume = volume.clamp(minVolume, maxVolume);
    }
    
    // Calculate stereo balance (-1.0 = left, 0.0 = center, 1.0 = right)
    double balance = 0.0;
    if (distance > 0) {
      final direction = soundPosition - playerPosition;
      // Simplified stereo calculation (just X axis)
      balance = (direction.x / maxDistance).clamp(-1.0, 1.0);
    }
    
    return AudioSpatialData(
      volume: volume,
      balance: balance,
      distance: distance,
    );
  }

  /// Calculate 3D audio with wall occlusion effects
  AudioSpatialData calculate3DAudioWithOcclusion(
    Vector2 playerPosition, 
    Vector2 soundPosition,
    List<Wall> walls, {
    double maxDistance = maxAudioDistance
  }) {
    // First calculate base 3D audio without occlusion
    final baseAudio = calculate3DAudio(playerPosition, soundPosition, maxDistance: maxDistance);
    
    // If sound is already at zero volume due to distance, no need to calculate occlusion
    if (baseAudio.volume <= 0.0) {
      return baseAudio;
    }
    
    // Calculate wall intersections between player and sound source
    final intersections = LineIntersection.calculateWallIntersections(
      playerPosition, 
      soundPosition, 
      walls
    );
    
    if (intersections.isEmpty) {
      // No walls blocking, return base audio
      return baseAudio;
    }
    
    // Calculate occlusion effects
    final occlusionStrength = LineIntersection.calculateOcclusionStrength(intersections);
    final mufflingStrength = LineIntersection.calculateMufflingStrength(intersections);
    final wallCount = intersections.map((i) => i.wall).toSet().length;
    
    // Apply occlusion to the base audio data
    return baseAudio.withOcclusion(
      occlusionStrength: occlusionStrength,
      mufflingStrength: mufflingStrength,
      wallCount: wallCount,
    );
  }

  /// Calculate wall occlusion data without applying it to audio
  /// Useful for debug visualization and analysis
  Map<String, dynamic> calculateWallOcclusionData(
    Vector2 playerPosition,
    Vector2 soundPosition, 
    List<Wall> walls
  ) {
    final intersections = LineIntersection.calculateWallIntersections(
      playerPosition,
      soundPosition,
      walls
    );
    
    return {
      'intersections': intersections,
      'wallCount': intersections.map((i) => i.wall).toSet().length,
      'occlusionStrength': LineIntersection.calculateOcclusionStrength(intersections),
      'mufflingStrength': LineIntersection.calculateMufflingStrength(intersections),
      'hasLineOfSight': intersections.isEmpty,
    };
  }

  Future<void> play3DSound(String soundName, Vector2 playerPosition, Vector2 soundPosition, {double maxDistance = maxAudioDistance}) async {
    final spatialData = calculate3DAudio(playerPosition, soundPosition, maxDistance: maxDistance);
    
    if (spatialData.volume > 0) {
      await playSound(soundName, volume: spatialData.volume);
      await setSoundBalance(soundName, spatialData.balance);
    } else {
      await stopSound(soundName);
    }
  }

  // New methods for always-playing sound sources
  Future<void> startContinuousSound(String soundName) async {
    final player = _players[soundName];
    if (player != null && !(_isContinuousPlaying[soundName] ?? false)) {
      // Start at zero volume to avoid sudden audio
      await player.setVolume(0.0);
      await player.resume();
      _isContinuousPlaying[soundName] = true;
      _currentVolumes[soundName] = 0.0;
      print('🔊 DEBUG: Started continuous playback for $soundName');
    }
  }

  Future<void> updateContinuousSoundVolume(String soundName, Vector2 playerPosition, Vector2 soundPosition, {double maxDistance = maxAudioDistance}) async {
    if (!(_isContinuousPlaying[soundName] ?? false)) {
      // If not continuously playing, start it
      await startContinuousSound(soundName);
      return;
    }

    final spatialData = calculate3DAudio(playerPosition, soundPosition, maxDistance: maxDistance);
    final targetVolume = spatialData.volume;
    final currentVolume = _currentVolumes[soundName] ?? 0.0;
    
    // Smooth volume transitions to avoid audio artifacts
    const volumeChangeRate = 2.0; // Volume change per second
    const deltaTime = 1.0 / 60.0; // Assume 60 FPS for smooth transitions
    
    double newVolume;
    if ((targetVolume - currentVolume).abs() < volumeChangeRate * deltaTime) {
      newVolume = targetVolume;
    } else if (targetVolume > currentVolume) {
      newVolume = currentVolume + (volumeChangeRate * deltaTime);
    } else {
      newVolume = currentVolume - (volumeChangeRate * deltaTime);
    }
    
    newVolume = newVolume.clamp(minVolume, maxVolume);
    
    if ((newVolume - currentVolume).abs() > 0.001) {
      await setSoundVolume(soundName, newVolume);
      await setSoundBalance(soundName, spatialData.balance);
      _currentVolumes[soundName] = newVolume;
    }
  }

  /// Update continuous sound volume with wall occlusion calculations
  Future<void> updateContinuousSoundVolumeWithOcclusion(
    String soundName, 
    Vector2 playerPosition, 
    Vector2 soundPosition,
    List<Wall> walls, {
    double maxDistance = maxAudioDistance
  }) async {
    if (!(_isContinuousPlaying[soundName] ?? false)) {
      // If not continuously playing, start it
      await startContinuousSound(soundName);
      return;
    }

    final spatialData = calculate3DAudioWithOcclusion(
      playerPosition, 
      soundPosition, 
      walls,
      maxDistance: maxDistance
    );
    
    final targetVolume = spatialData.volume;
    final currentVolume = _currentVolumes[soundName] ?? 0.0;
    final distance = playerPosition.distanceTo(soundPosition);
    
    // Calculate volume changes for smooth transitions
    
    // Smooth volume transitions to avoid audio artifacts
    const volumeChangeRate = 2.0; // Volume change per second
    const deltaTime = 1.0 / 60.0; // Assume 60 FPS for smooth transitions
    
    double newVolume;
    if ((targetVolume - currentVolume).abs() < volumeChangeRate * deltaTime) {
      newVolume = targetVolume;
    } else if (targetVolume > currentVolume) {
      newVolume = currentVolume + (volumeChangeRate * deltaTime);
    } else {
      newVolume = currentVolume - (volumeChangeRate * deltaTime);
    }
    
    newVolume = newVolume.clamp(minVolume, maxVolume);
    
    if ((newVolume - currentVolume).abs() > 0.001) {
      await setSoundVolume(soundName, newVolume);
      await setSoundBalance(soundName, spatialData.balance);
      _currentVolumes[soundName] = newVolume;
      
      // Volume changed - audio should now be audible
      
      // Debug output for occlusion effects
      if (spatialData.wallCount > 0) {
        print('🔇 DEBUG: $soundName occluded by ${spatialData.wallCount} walls - '
              'volume: ${newVolume.toStringAsFixed(2)} '
              '(occlusion: ${(spatialData.occlusionStrength * 100).toStringAsFixed(0)}%, '
              'muffling: ${(spatialData.mufflingStrength * 100).toStringAsFixed(0)}%)');
      }
    }
  }

  Future<void> setSoundVolume(String soundName, double volume) async {
    final player = _players[soundName];
    if (player != null) {
      final clampedVolume = volume.clamp(minVolume, maxVolume);
      await player.setVolume(clampedVolume);
      _currentVolumes[soundName] = clampedVolume;
    }
  }

  Future<void> setSoundBalance(String soundName, double balance) async {
    final player = _players[soundName];
    if (player != null) {
      // Note: AudioPlayer doesn't have built-in balance control
      // In a full implementation, we'd use a more advanced audio library
      // For MVP, we'll just adjust volume based on balance
      final leftVolume = balance < 0 ? 1.0 : (1.0 - balance);
      final rightVolume = balance > 0 ? 1.0 : (1.0 + balance);
      // This is a simplified approach - in production we'd need proper stereo control
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    _isLooping.clear();
    _isContinuousPlaying.clear();
    _currentVolumes.clear();
  }
}

class AudioSpatialData {
  final double volume;
  final double balance;
  final double distance;
  final double occlusionStrength;
  final double mufflingStrength;
  final int wallCount;

  AudioSpatialData({
    required this.volume,
    required this.balance,
    required this.distance,
    this.occlusionStrength = 0.0,
    this.mufflingStrength = 0.0,
    this.wallCount = 0,
  });
  
  /// Create a copy with occlusion data applied
  AudioSpatialData withOcclusion({
    required double occlusionStrength,
    required double mufflingStrength, 
    required int wallCount,
  }) {
    // Apply occlusion to volume (multiplicative)
    final occludedVolume = volume * (1.0 - occlusionStrength);
    
    return AudioSpatialData(
      volume: occludedVolume,
      balance: balance,
      distance: distance,
      occlusionStrength: occlusionStrength,
      mufflingStrength: mufflingStrength,
      wallCount: wallCount,
    );
  }
}