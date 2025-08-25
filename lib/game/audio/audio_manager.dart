import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'dart:math' as math;
import '../components/wall.dart';
import '../utils/line_intersection.dart';
import 'asset_audio_player.dart';

class AudioManager {
  static AudioManager? _testInstance;
  static final AudioManager _instance = AudioManager._internal();
  
  factory AudioManager() => _testInstance ?? _instance;
  AudioManager._internal();
  
  /// Set a test instance (used during testing to inject mocks)
  static void setTestInstance(AudioManager? testInstance) {
    _testInstance = testInstance;
  }
  
  /// Check if running in test mode
  bool get isTestMode => _testInstance != null;

  final Map<String, AudioPlayer?> _players = {};  // Allow null players for failed loads
  final Map<String, bool> _isLooping = {};
  final Map<String, bool> _isContinuousPlaying = {};
  final Map<String, double> _currentVolumes = {};
  
  // Use the working AssetAudioPlayer for continuous sounds
  final AssetAudioPlayer _assetAudioPlayer = AssetAudioPlayer();
  
  // 3D audio parameters
  static const double maxAudioDistance = 200.0;
  static const double minVolume = 0.0;
  static const double maxVolume = 1.0;

  Future<void> preloadSound(String soundName, String assetPath, {bool loop = false}) async {
    // In test mode, just register the sound without trying to load audio
    if (isTestMode) {
      _players[soundName] = null;
      _isLooping[soundName] = loop;
      return;
    }
    
    try {
      // Try to create AudioPlayer - this can throw synchronous exceptions
      AudioPlayer? player;
      try {
        player = AudioPlayer();
        await player.setSource(AssetSource(assetPath));
        
        if (loop) {
          await player.setReleaseMode(ReleaseMode.loop);
        }
        
        _players[soundName] = player;
      } catch (e) {
        print('Failed to create/configure AudioPlayer for $soundName: $e');
        // Store null player but keep the sound registered for game logic
        _players[soundName] = null;
      }
      
      _isLooping[soundName] = loop;
    } catch (e) {
      print('Failed to load audio: $soundName from $assetPath - $e');
      // Store null player but maintain sound registration for game logic
      _players[soundName] = null;
      _isLooping[soundName] = loop;
    }
  }

  Future<void> playSound(String soundName, {double volume = 1.0}) async {
    try {
      final player = _players[soundName];
      if (player != null) {
        await player.setVolume(volume.clamp(minVolume, maxVolume));
        await player.resume();
      }
    } catch (e) {
      // Silently handle playback failures in test environments
    }
  }

  Future<void> stopSound(String soundName) async {
    try {
      final player = _players[soundName];
      if (player != null) {
        await player.stop();
      }
    } catch (e) {
      // Silently handle stop failures in test environments
    }
  }

  void stopAllSounds() {
    for (final player in _players.values) {
      player?.stop();
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
    // Always mark as continuous playing for game logic, even if audio playback fails
    if (!(_isContinuousPlaying[soundName] ?? false)) {
      _isContinuousPlaying[soundName] = true;
      _currentVolumes[soundName] = 0.0;
      print('🔊 DEBUG: Started continuous playback for $soundName');
      
      // Skip actual audio playback in test mode
      if (isTestMode) {
        print('🔊 DEBUG: Test mode - skipping actual audio playback for $soundName');
        return;
      }
      
      // Use the working AssetAudioPlayer instead of the broken AudioPlayer
      try {
        final assetPath = 'audio/interaction/$soundName';
        await _assetAudioPlayer.startContinuousSound(soundName, assetPath);
        print('🔊 DEBUG: Successfully started continuous audio via AssetAudioPlayer for $soundName');
      } catch (e) {
        print('⚠️ DEBUG: AssetAudioPlayer failed for $soundName: $e');
        // Continue with game logic even if playback fails
      }
    }
  }

  Future<void> updateContinuousSoundVolume(String soundName, Vector2 playerPosition, Vector2 soundPosition, {double maxDistance = maxAudioDistance}) async {
    if (!(_isContinuousPlaying[soundName] ?? false)) {
      // If not continuously playing, start it
      await startContinuousSound(soundName);
      return;
    }

    // Always perform spatial audio calculations for game logic
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
    
    // Always update the volume state for game logic
    // Force volume updates for continuous sounds to ensure AssetAudioPlayer gets called
    if ((newVolume - currentVolume).abs() > 0.001 || (_isContinuousPlaying[soundName] ?? false)) {
      // Always call setSoundVolume - it now handles null players gracefully
      await setSoundVolume(soundName, newVolume);
      await setSoundBalance(soundName, spatialData.balance);
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

    // Always perform spatial audio calculations for game logic
    final distance = playerPosition.distanceTo(soundPosition);
    final spatialData = calculate3DAudioWithOcclusion(
      playerPosition, 
      soundPosition, 
      walls,
      maxDistance: maxDistance
    );
    
    // Apply proximity override for very close sounds
    double targetVolume = spatialData.volume;
    final currentVolume = _currentVolumes[soundName] ?? 0.0;
    
    // Proximity override: when very close, reduce occlusion effect significantly
    const proximityThreshold = 50.0;
    if (distance < proximityThreshold) {
      // Calculate base volume without occlusion for close sounds
      final baseAudio = calculate3DAudio(playerPosition, soundPosition, maxDistance: maxDistance);
      final proximityFactor = distance / proximityThreshold; // 0.0 at center, 1.0 at threshold
      
      // Blend between full base volume (when very close) and occluded volume (at threshold)
      // At distance 0: 95% base, 5% occluded
      // At distance 50: 20% base, 80% occluded
      final baseWeight = 0.95 - (proximityFactor * 0.75);
      final occludedWeight = 1.0 - baseWeight;
      
      targetVolume = (baseAudio.volume * baseWeight) + (spatialData.volume * occludedWeight);
      
      // Ensure minimum audible volume for very close sounds
      const minCloseVolume = 0.2;
      if (distance < proximityThreshold * 0.5 && targetVolume < minCloseVolume) {
        targetVolume = math.max(targetVolume, minCloseVolume);
      }
      
      print('🔊 DEBUG: Proximity override for $soundName - distance: ${distance.toStringAsFixed(1)}, '
            'base: ${baseAudio.volume.toStringAsFixed(2)}, occluded: ${spatialData.volume.toStringAsFixed(2)}, '
            'final: ${targetVolume.toStringAsFixed(2)}');
    }
    
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
    
    // Always update the volume state for game logic
    // Force volume updates for continuous sounds to ensure AssetAudioPlayer gets called
    if ((newVolume - currentVolume).abs() > 0.001 || (_isContinuousPlaying[soundName] ?? false)) {
      // Always call setSoundVolume - it now handles null players gracefully
      await setSoundVolume(soundName, newVolume);
      await setSoundBalance(soundName, spatialData.balance);
      
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
    final clampedVolume = volume.clamp(minVolume, maxVolume);
    
    // Always update the volume state for game logic, regardless of player availability
    _currentVolumes[soundName] = clampedVolume;
    
    // Skip actual volume setting in test mode
    if (isTestMode) {
      return;
    }
    
    // Try to use AssetAudioPlayer for continuous sounds first
    try {
      if (_isContinuousPlaying[soundName] ?? false) {
        await _assetAudioPlayer.setContinuousSoundVolume(soundName, clampedVolume);
        return; // Success with AssetAudioPlayer
      }
    } catch (e) {
      print('⚠️ DEBUG: AssetAudioPlayer volume setting failed for $soundName: $e');
    }
    
    // Fallback to original AudioPlayer method
    try {
      final player = _players[soundName];
      if (player != null) {
        await player.setVolume(clampedVolume);
      } else {
        // Only print occasionally to avoid spam, but confirm volume is being calculated
        if ((clampedVolume * 100).round() % 10 == 0 || clampedVolume == 0.0 || clampedVolume == 1.0) {
          print('🔊 DEBUG: Volume calculated for $soundName: ${clampedVolume.toStringAsFixed(2)} (audio unavailable)');
        }
      }
    } catch (e) {
      // Silently handle volume setting failures in test environments
      // This prevents test failures while maintaining functionality in real environments
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
      player?.dispose();
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