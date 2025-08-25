import 'package:flame/components.dart';
import 'audio_manager.dart';
import '../components/player.dart';
import '../components/wall.dart';
import '../levels/level.dart';

class SpatialAudioComponent extends Component {
  final String soundName;
  final String assetPath;
  final double maxDistance;
  final bool isLooping;
  
  late AudioManager _audioManager;
  bool _hasStartedPlaying = false;
  Vector2? _lastPlayerPosition;
  double _lastVolume = 0.0;
  
  SpatialAudioComponent({
    required this.soundName,
    required this.assetPath,
    this.maxDistance = 200.0,
    this.isLooping = true,
  });
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _audioManager = AudioManager();
    
    // Preload and immediately start playing the sound
    await _audioManager.preloadSound(soundName, assetPath, loop: isLooping);
    
    // Start playing immediately at zero volume
    // This ensures the sound is always running but may be inaudible
    await _audioManager.startContinuousSound(soundName);
    _hasStartedPlaying = true;
    
    print('🔊 DEBUG: Started continuous playback for $soundName');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (!_hasStartedPlaying) return;
    
    // Find the player in the game
    final player = findGame()?.children
        .whereType<PositionComponent>()
        .expand((component) => component.children)
        .whereType<Player>()
        .firstOrNull;
    
    if (player == null) return;
    
    // Only update audio if player has moved significantly or if this is the first update
    if (_lastPlayerPosition == null || 
        player.position.distanceTo(_lastPlayerPosition!) > 5.0) {
      
      _lastPlayerPosition = player.position.clone();
      
      // Get the position of the parent component (sound source)
      // Fix: Safely access parent position with proper null handling
      Vector2 soundPosition;
      if (parent is PositionComponent) {
        soundPosition = (parent as PositionComponent).position.clone();
        // Add size offset to get center position if parent has size
        if (parent is SizeProvider) {
          soundPosition += (parent as SizeProvider).size / 2;
        }
      } else {
        soundPosition = Vector2.zero();
      }
      
      // Get walls for occlusion calculation
      final walls = _getWallsFromLevel();
      
      // Update volume with wall occlusion if walls are available
      if (walls.isNotEmpty) {
        _audioManager.updateContinuousSoundVolumeWithOcclusion(
          soundName,
          player.position,
          soundPosition,
          walls,
          maxDistance: maxDistance,
        );
      } else {
        // Fallback to regular volume update if no walls found
        _audioManager.updateContinuousSoundVolume(
          soundName,
          player.position,
          soundPosition,
          maxDistance: maxDistance,
        );
      }
      
      // Debug output for volume changes
      final distance = player.position.distanceTo(soundPosition);
      final currentVolume = distance <= maxDistance ? 
          ((maxDistance - distance) / maxDistance).clamp(0.0, 1.0) : 0.0;
      
      if ((currentVolume - _lastVolume).abs() > 0.1) {
        print('🔊 DEBUG: $soundName volume: ${currentVolume.toStringAsFixed(2)} (distance: ${distance.toStringAsFixed(1)})');
        _lastVolume = currentVolume;
      }
    }
  }
  
  // Remove old play/stop methods as sounds are always playing
  // Keep only for compatibility if needed elsewhere
  void play() {
    // Sound is always playing - this is a no-op for always-playing sounds
    print('🔊 DEBUG: play() called on $soundName - already continuously playing');
  }
  
  void stop() {
    // For always-playing sounds, we just set volume to zero instead of stopping
    _audioManager.setSoundVolume(soundName, 0.0);
    print('🔊 DEBUG: stop() called on $soundName - muted instead of stopped');
  }
  
  /// Get walls from the parent level for occlusion calculations
  List<Wall> _getWallsFromLevel() {
    // Try to find the level component in the hierarchy
    Component? current = this;
    while (current != null) {
      if (current is Level) {
        return current.getAllWalls();
      }
      current = current.parent;
    }
    
    // If we can't find a level, try to get walls from the game directly
    final game = findGame();
    if (game != null) {
      return game.children
          .expand((component) => component.children)
          .whereType<Wall>()
          .toList();
    }
    
    return [];
  }
  
  @override
  void onRemove() {
    // Only stop when component is completely removed
    _audioManager.stopSound(soundName);
    print('🔊 DEBUG: Stopped $soundName on component removal');
    super.onRemove();
  }
}