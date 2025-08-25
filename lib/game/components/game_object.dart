import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../audio/audio_manager.dart';
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
  /// Includes performance throttling to reduce CPU usage
  void updateSpatialAudioWithOcclusion(Vector2 playerPosition, List<Wall> walls) {
    if (type != GameObjectType.soundSource || soundFile == null) return;
    
    final audioManager = AudioManager();
    
    // Initialize continuous audio if not already done
    if (!_hasInitializedAudio) {
      audioManager.startContinuousSound(soundFile!);
      _hasInitializedAudio = true;
      print('🔊 DEBUG: Initialized continuous audio for ${soundFile!} at ${position}');
    }
    
    // Throttle audio updates for performance (30 Hz instead of 60 Hz)
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (currentTime - _lastAudioUpdateTime < _audioUpdateInterval) {
      return;
    }
    _lastAudioUpdateTime = currentTime;
    
    // Update volume with wall occlusion effects
    final soundPosition = position + size / 2;
    
    // Update volume with wall occlusion effects
    audioManager.updateContinuousSoundVolumeWithOcclusion(
      soundFile!,
      playerPosition,
      soundPosition,
      walls,
      maxDistance: soundRadius,
    );
  }
}