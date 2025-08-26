import 'package:flame/components.dart';
import '../components/wall.dart';
import '../components/game_object.dart';
import '../components/player.dart';
import '../dark_room_game.dart';
import '../audio/asset_audio_player.dart';
import '../audio/audio_manager.dart';
import '../systems/inventory_system.dart';
import '../systems/narration_system.dart';
import '../systems/health_system.dart';
import '../systems/level_progress_manager.dart';
import '../utils/game_logger.dart';

abstract class Level extends Component with HasGameReference<DarkRoomGame> {
  final String name;
  final String description;
  late Vector2 playerSpawn;
  final List<String> inventory = []; // Legacy - kept for compatibility
  late AssetAudioPlayer _audioPlayer;
  late final GameCategoryLogger _logger;
  
  // New systems for automatic pickup and health
  late InventorySystem inventorySystem;
  late NarrationSystem narrationSystem;
  late HealthSystem healthSystem;
  
  // Performance optimization: cache wall list
  List<Wall>? _cachedWalls;
  bool _wallsCacheValid = false;
  
  // Debug timing for spatial audio logs
  double _lastDebugTime = 0.0;
  
  // Track level start time for completion statistics
  DateTime? _levelStartTime;
  
  // Test isolation mode
  bool _testIsolationMode = false;
  
  Level({
    required this.name,
    required this.description,
    Vector2? spawn,
  }) {
    playerSpawn = spawn ?? Vector2(400, 300);
  }
  
  /// Enable test isolation mode to prevent automatic system connections
  void enableTestIsolation() {
    _testIsolationMode = true;
    // Initialize logger for test scenarios (safe to call multiple times)
    gameLogger.initialize();
    _logger = gameLogger.system;
    _logger.test('LEVEL: Test isolation enabled for $name');
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    gameLogger.initialize();
    _logger = gameLogger.system;
    _audioPlayer = AssetAudioPlayer();
    _levelStartTime = DateTime.now();
    
    // Initialize new systems
    inventorySystem = InventorySystem();
    narrationSystem = NarrationSystem();
    healthSystem = HealthSystem();
    add(inventorySystem);
    add(narrationSystem);
    add(healthSystem);
    
    // Connect systems
    inventorySystem.setNarrationSystem(narrationSystem);
    
    await buildLevel();
    await initializeSoundSources();
    // Note: _initializePlayerSystems() is called after player is added to level
    
    _logger.process('LEVEL: Started level "$name" at $_levelStartTime');
  }
  
  Future<void> initializeSoundSources() async {
    try {
      final audioManager = AudioManager();
      final objectsWithSound = children.whereType<GameObject>()
          .where((obj) => obj.soundFile != null);
      
      _logger.debug('DEBUG: Initializing ${objectsWithSound.length} sound sources for level: $name');
      
      if (objectsWithSound.isEmpty) {
        _logger.warning('DEBUG: No sound sources found in level');
        return;
      }
      
      for (final soundObject in objectsWithSound) {
        if (soundObject.soundFile != null) {
          try {
            final loop = soundObject.type == GameObjectType.soundSource;
            
            // Preload the sound
            await audioManager.preloadSound(
              soundObject.soundFile!,
              'audio/interaction/${soundObject.soundFile!}',
              loop: loop,
            );
            
            // Immediately start continuous playback for sound sources
            if (soundObject.type == GameObjectType.soundSource) {
              await audioManager.startContinuousSound(soundObject.soundFile!);
              _logger.debug('DEBUG: Started continuous playback for ${soundObject.soundFile!} at position ${soundObject.position}');
            }
          } catch (e) {
            _logger.warning('DEBUG: Failed to initialize sound ${soundObject.soundFile!}: $e');
            // Continue with other sounds even if this one fails
          }
        }
      }
      
      _logger.debug('DEBUG: All sound sources initialized and playing for level: $name');
    } catch (e) {
      _logger.warning('DEBUG: Failed to initialize sound sources for level $name: $e');
      // Level can continue without audio in test environments
    }
  }
  
  // Override this to build the level
  Future<void> buildLevel();
  
  // Helper method to create room boundaries
  void createRoomBoundaries(Vector2 roomSize) {
    // Top wall
    add(Wall(
      position: Vector2(0, 0),
      size: Vector2(roomSize.x, 20),
    ));
    
    // Bottom wall
    add(Wall(
      position: Vector2(0, roomSize.y - 20),
      size: Vector2(roomSize.x, 20),
    ));
    
    // Left wall
    add(Wall(
      position: Vector2(0, 0),
      size: Vector2(20, roomSize.y),
    ));
    
    // Right wall
    add(Wall(
      position: Vector2(roomSize.x - 20, 0),
      size: Vector2(20, roomSize.y),
    ));
  }
  
  // Helper to add an object to the level
  void addObject(GameObject object) {
    add(object);
  }
  
  /// Initialize player's system references (call after player is added to level)
  Future<void> initializePlayerSystems() async {
    if (_testIsolationMode) {
      _logger.test('LEVEL: Skipping player system initialization in test isolation mode');
      return;
    }
    
    final player = children.whereType<Player>().firstOrNull;
    if (player != null) {
      player.setInventorySystem(inventorySystem);
      player.setHealthSystem(healthSystem);
      _logger.success('LEVEL: Connected player to inventory and health systems');
    } else {
      _logger.warning('LEVEL: No player found to connect systems to');
    }
  }
  
  // Check for player interaction with objects (legacy for doors)
  void checkInteractions() {
    final player = children.whereType<Player>().firstOrNull;
    if (player == null) return;
    
    final objects = children.whereType<GameObject>();
    
    for (final object in objects) {
      if (!object.isActive) continue;
      
      final distance = player.getDistanceTo(
        object.position + object.size / 2
      );
      
      // Check door and interactable interactions (items are handled automatically by player)
      if ((object.type == GameObjectType.door || object.type == GameObjectType.interactable) && distance < 40) {
        handleObjectInteraction(object, player);
      }
    }
  }
  
  void handleObjectInteraction(GameObject object, Player player) {
    // Allow door interactions regardless of key status - doors should always give feedback
    // Only check canInteract for non-door objects
    if (object.type != GameObjectType.door && !object.canInteract(inventorySystem.items)) {
      return;
    }
    
    object.interact(inventorySystem.items);
    
    switch (object.type) {
      case GameObjectType.item:
        // Items are now handled automatically by the player's pickup system
        // This code path should not be reached anymore
        _logger.warning('WARNING: Item interaction through legacy system - should use automatic pickup');
        break;
        
      case GameObjectType.door:
        _logger.debug('DEBUG: Door interaction - ${object.name}, isLocked: ${object.isLocked}, requiredKey: ${object.requiredKey}');
        
        if (object.isLocked && object.requiredKey != null) {
          _logger.debug('DEBUG: Checking for key "${object.requiredKey}" in inventory: ${inventorySystem.items}');
          
          if (inventorySystem.hasItem(object.requiredKey!)) {
            _logger.success('DEBUG: Key found! Unlocking door');
            object.isLocked = false;
            narrationSystem.narrateDoorInteraction('The door unlocks with a soft click.');
            _audioPlayer.playDoorOpenSound();
          } else {
            _logger.error('DEBUG: Key not found in inventory');
            narrationSystem.narrateDoorInteraction('The door is locked. You need to find the right key.');
          }
        }
        
        if (!object.isLocked) {
          _logger.success('DEBUG: Door is unlocked - completing level');
          // Complete the level
          _audioPlayer.playDoorOpenSound();
          narrationSystem.narrateLevelComplete(name);
          completeLevel();
        }
        break;
        
      case GameObjectType.interactable:
      case GameObjectType.soundSource:
        // These don't require manual interaction
        break;
        
      case GameObjectType.healthArtifact:
        // Health artifacts are handled automatically by the player's pickup system
        // This code path should not be reached anymore
        _logger.warning('WARNING: Health artifact interaction through legacy system - should use automatic pickup');
        break;
    }
  }
  
  void completeLevel() async {
    _logger.debug('DEBUG: Would play level complete sound (DISABLED)');
    // _audioPlayer.playLevelCompleteSound(); // Temporarily disabled for debugging
    _logger.success('Level Complete: $name');
    
    // Save progress data
    final levelId = _getLevelIdFromName(name);
    if (levelId != null && _levelStartTime != null) {
      final completionTime = DateTime.now().difference(_levelStartTime!);
      final healthRemaining = healthSystem.currentHealth;
      
      final progressManager = LevelProgressManager();
      await progressManager.markLevelCompleted(
        levelId,
        completionTime: completionTime,
        attempts: 1, // Implementation Note: Track actual attempts in future release
        healthRemaining: healthRemaining,
      );
      
      _logger.success('LEVEL: Saved completion data for $levelId - Time: ${completionTime.inSeconds}s, Health: ${healthRemaining.toStringAsFixed(1)}%');
    }
    
    game.completeLevel();
  }
  
  String? _getLevelIdFromName(String levelName) {
    if (levelName.contains('Tutorial') || levelName.contains('First Steps')) {
      return 'tutorial';
    } else if (levelName.contains('Simple Escape') || levelName.contains('Antechamber')) {
      return 'escape_room';
    } else if (levelName.contains('Laboratory') || levelName.contains('Chemical Analysis')) {
      return 'laboratory';
    } else if (levelName.contains('Basement') || levelName.contains('Industrial Underground')) {
      return 'basement';
    } else if (levelName.contains('Office Complex') || levelName.contains('Corporate Tower')) {
      return 'office_complex';
    }
    return null;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    checkInteractions();
    updateSpatialAudio();
  }
  
  void updateSpatialAudio() {
    final player = children.whereType<Player>().firstOrNull;
    if (player == null) return;
    
    final soundSources = children.whereType<GameObject>()
        .where((obj) => obj.type == GameObjectType.soundSource);
    
    // Get all walls for occlusion calculations
    final walls = getAllWalls();
    
    // Debug logging every 5 seconds (reduced frequency)
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (currentTime - _lastDebugTime > 5.0) {
      _logger.debug('LEVEL: Updating spatial audio for ${soundSources.length} sound sources, player at ${player.position}');
      _lastDebugTime = currentTime;
    }
    
    for (final soundSource in soundSources) {
      // Fire-and-forget async call to avoid blocking the update loop
      // Error handling is done within the GameObject method
      soundSource.updateSpatialAudioWithOcclusion(player.position, walls).catchError((e) {
        _logger.error('LEVEL: Error updating spatial audio for ${soundSource.soundFile}: $e');
      });
    }
  }
  
  /// Get all walls in this level for occlusion calculations
  /// Uses caching for performance optimization
  List<Wall> getAllWalls() {
    if (!_wallsCacheValid || _cachedWalls == null) {
      _cachedWalls = children.whereType<Wall>().toList();
      _wallsCacheValid = true;
    }
    return _cachedWalls!;
  }
  
  /// Invalidate wall cache when walls are added/removed
  void _invalidateWallCache() {
    _wallsCacheValid = false;
  }
  
  @override
  bool onChildrenChanged(Component child, ChildrenChangeType type) {
    if (child is Wall) {
      _invalidateWallCache();
    }
    super.onChildrenChanged(child, type);
    return true;
  }
}