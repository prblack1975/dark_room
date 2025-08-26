import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../audio/audio_manager.dart';
import '../utils/platform_utils.dart';
import 'wall.dart';

enum GameObjectType {
  item,
  door,
  interactable,
  soundSource,
  healthArtifact,
}

class GameObject extends PositionComponent with CollisionCallbacks {
  final GameObjectType type;
  final String name;
  final String description;
  final String? atmosphericDescription; // Enhanced description for narration
  bool isActive = true;
  
  // For items
  bool isPickedUp = false;
  double pickupRadius = 35.0; // Default pickup radius for automatic pickup
  
  // For health artifacts
  double healingAmount = 50.0; // Default healing amount
  
  // For doors
  bool isLocked = true;
  String? requiredKey;
  
  // For sound sources
  double soundRadius = 100.0;
  String? soundFile;
  bool _hasInitializedAudio = false;
  
  // Performance optimization: throttle audio updates
  double _lastAudioUpdateTime = 0.0;
  static const double _audioUpdateInterval = 1.0 / 30.0; // Update at 30 Hz instead of 60 Hz
  
  // Fire OS fallback system for when continuous audio fails
  bool _continuousAudioFailed = false;
  double _lastFallbackSoundTime = 0.0;
  double _fallbackSoundInterval = 2.0; // Play fallback sounds every 2 seconds when close
  double _lastProximityVolume = 0.0;
  
  GameObject({
    required this.type,
    required this.name,
    required this.description,
    this.atmosphericDescription,
    required Vector2 position,
    Vector2? size,
    this.requiredKey,
    this.soundRadius = 100.0,
    this.soundFile,
    this.pickupRadius = 35.0,
    this.healingAmount = 50.0,
  }) : super(
    position: position,
    size: size ?? Vector2.all(30),
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add hitbox for collision detection
    add(RectangleHitbox(
      size: size,
    ));
  }
  
  @override
  void render(Canvas canvas) {
    // Objects are invisible in normal gameplay
    // Debug mode will handle visualization
  }
  
  void interact(List<String> inventory) {
    switch (type) {
      case GameObjectType.item:
        if (!isPickedUp) {
          isPickedUp = true;
          isActive = false;
          // Will be added to inventory by the level
        }
        break;
        
      case GameObjectType.healthArtifact:
        if (!isPickedUp) {
          isPickedUp = true;
          isActive = false;
          // Will be processed by the health system
        }
        break;
        
      case GameObjectType.door:
        if (isLocked && requiredKey != null) {
          if (inventory.contains(requiredKey)) {
            isLocked = false;
            // Door is now unlocked
          }
        }
        if (!isLocked) {
          // Level completion will be triggered
        }
        break;
        
      case GameObjectType.interactable:
      case GameObjectType.soundSource:
        // These might trigger sounds or other effects
        break;
    }
  }
  
  bool canInteract(List<String> inventory) {
    switch (type) {
      case GameObjectType.item:
        return !isPickedUp;
        
      case GameObjectType.healthArtifact:
        return !isPickedUp;
        
      case GameObjectType.door:
        if (isLocked && requiredKey != null) {
          return inventory.contains(requiredKey);
        }
        return !isLocked;
        
      case GameObjectType.interactable:
      case GameObjectType.soundSource:
        return isActive;
    }
  }
  
  void updateSpatialAudio(Vector2 playerPosition) {
    if (type != GameObjectType.soundSource || soundFile == null) return;
    
    final audioManager = AudioManager();
    
    // Initialize continuous audio if not already done
    if (!_hasInitializedAudio) {
      audioManager.startContinuousSound(soundFile!);
      _hasInitializedAudio = true;
      print('🔊 DEBUG: Initialized continuous audio for ${soundFile!} at ${position}');
    }
    
    // Always update volume based on distance - never stop the sound
    final soundPosition = position + size / 2;
    audioManager.updateContinuousSoundVolume(
      soundFile!,
      playerPosition,
      soundPosition,
      maxDistance: soundRadius,
    );
  }
  
  /// Update spatial audio with wall occlusion calculations
  /// Includes performance throttling to reduce CPU usage and Fire OS fallback
  Future<void> updateSpatialAudioWithOcclusion(Vector2 playerPosition, List<Wall> walls) async {
    if (type != GameObjectType.soundSource || soundFile == null) return;
    
    final audioManager = AudioManager();
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Check if continuous audio needs initialization
    // Note: Level may have already initialized this during level load
    if (!_hasInitializedAudio) {
      // Check if AudioManager already has this sound playing
      final isAlreadyPlaying = audioManager.isContinuouslyPlaying(soundFile!);
      
      if (isAlreadyPlaying) {
        print('🔊 GAME OBJECT: Audio for ${soundFile!} already initialized by Level');
        _hasInitializedAudio = true;
      } else {
        try {
          print('🔊 GAME OBJECT: Level did not initialize ${soundFile!}, initializing now');
          await audioManager.startContinuousSound(soundFile!);
          _hasInitializedAudio = true;
          print('✅ GAME OBJECT: Successfully initialized continuous audio for ${soundFile!}');
        } catch (e) {
          print('❌ GAME OBJECT: Failed to initialize continuous audio for ${soundFile!}: $e');
          if (PlatformUtils.shouldUseFireOSMode) {
            print('🔥 FIRE OS: Marking continuous audio as failed, enabling fallback mode');
            _continuousAudioFailed = true;
          }
          _hasInitializedAudio = true; // Don't keep retrying
        }
      }
    }
    
    // Throttle audio updates for performance (30 Hz instead of 60 Hz)
    if (currentTime - _lastAudioUpdateTime < _audioUpdateInterval) {
      return;
    }
    _lastAudioUpdateTime = currentTime;
    
    // Calculate spatial audio data
    final soundPosition = position + size / 2;
    final spatialData = audioManager.calculate3DAudioWithOcclusion(
      playerPosition, 
      soundPosition, 
      walls,
      maxDistance: soundRadius,
    );
    
    // Store volume for fallback system
    _lastProximityVolume = spatialData.volume;
    
    // Try continuous audio first
    if (!_continuousAudioFailed) {
      try {
        await audioManager.updateContinuousSoundVolumeWithOcclusion(
          soundFile!,
          playerPosition,
          soundPosition,
          walls,
          maxDistance: soundRadius,
        );
      } catch (e) {
        print('❌ GAME OBJECT: Continuous audio update failed for ${soundFile!}: $e');
        if (PlatformUtils.shouldUseFireOSMode) {
          print('🔥 FIRE OS: Continuous audio failed, switching to fallback mode');
          _continuousAudioFailed = true;
        }
      }
    }
    
    // Fire OS fallback: periodic one-shot sounds when continuous audio fails
    if (_continuousAudioFailed && PlatformUtils.shouldUseFireOSMode) {
      await _handleFireOSAudioFallback(currentTime, spatialData.volume);
    }
  }
  
  /// Handle Fire OS audio fallback with periodic one-shot sounds
  Future<void> _handleFireOSAudioFallback(double currentTime, double volume) async {
    // Only play fallback sounds when volume is significant
    if (volume < 0.1) return;
    
    // Adjust interval based on volume (closer = more frequent)
    final dynamicInterval = _fallbackSoundInterval * (1.0 - volume * 0.5);
    
    if (currentTime - _lastFallbackSoundTime >= dynamicInterval) {
      _lastFallbackSoundTime = currentTime;
      
      try {
        // Play a one-shot version of the sound
        final audioManager = AudioManager();
        await audioManager.playSound(soundFile!, volume: volume * 0.3); // Reduced volume for fallback
        
        print('🔥 FIRE OS FALLBACK: Played one-shot $soundFile at ${(volume * 30).toInt()}% volume');
      } catch (e) {
        print('❌ FIRE OS FALLBACK: Even one-shot audio failed for $soundFile: $e');
      }
    }
  }
}