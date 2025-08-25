import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../audio/asset_audio_player.dart';
import '../systems/inventory_system.dart';
import '../systems/health_system.dart';
import 'wall.dart';
import 'game_object.dart';

class Player extends PositionComponent with CollisionCallbacks {
  static const double moveSpeed = 100.0; // pixels per second
  static const double playerSize = 20.0;
  
  Vector2 velocity = Vector2.zero();
  late AssetAudioPlayer _audioPlayer;
  Vector2 _lastValidPosition = Vector2.zero();
  bool _isColliding = false;
  double _lastCollisionSoundTime = 0.0;
  
  // Reference to inventory system for automatic pickup
  InventorySystem? _inventorySystem;
  
  // Reference to health system for damage and healing
  HealthSystem? _healthSystem;
  
  Player({required Vector2 position}) : super(
    position: position,
    size: Vector2.all(playerSize),
    anchor: Anchor.center,
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    _audioPlayer = AssetAudioPlayer();
    _lastValidPosition = position.clone();
    
    // Add circular hitbox for collision detection
    add(CircleHitbox(
      radius: playerSize / 2,
      position: size / 2,
      anchor: Anchor.center,
    ));
  }
  
  void updateMovement(Set<LogicalKeyboardKey> keysPressed) {
    velocity = Vector2.zero();
    
    // Vertical movement
    if (keysPressed.contains(LogicalKeyboardKey.keyW) || 
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      velocity.y = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) || 
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      velocity.y = 1;
    }
    
    // Horizontal movement
    if (keysPressed.contains(LogicalKeyboardKey.keyA) || 
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      velocity.x = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) || 
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      velocity.x = 1;
    }
    
    // Normalize diagonal movement
    if (velocity.length > 0) {
      velocity.normalize();
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Store position before movement
    if (!_isColliding) {
      _lastValidPosition = position.clone();
    }
    
    // Apply movement
    if (velocity.length > 0) {
      final movement = velocity * moveSpeed * dt;
      position += movement;
    }
    
    // Check for automatic item pickup
    _checkForItemPickup();
    
    // Reset collision flag for next frame
    _isColliding = false;
  }
  
  @override
  bool onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    // Check if colliding with a wall
    if (other is Wall) {
      final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      
      // Play collision sound with cooldown to prevent audio system overload
      if ((currentTime - _lastCollisionSoundTime) > 0.5) { // 500ms cooldown
        print('🟥 DEBUG: COLLISION - Playing collision sound (cooldown: ${(currentTime - _lastCollisionSoundTime).toStringAsFixed(3)}s)');
        _audioPlayer.playCollisionSound();
        _lastCollisionSoundTime = currentTime;
      }
      
      _isColliding = true;
      
      // Revert to last valid position to prevent moving through walls
      position = _lastValidPosition.clone();
      
      // Calculate push-back direction for smoother collision
      if (intersectionPoints.isNotEmpty) {
        final collisionPoint = intersectionPoints.first;
        final pushBack = position - collisionPoint;
        
        if (pushBack.length > 0) {
          pushBack.normalize();
          // Small push-back to prevent sticking to walls
          position += pushBack * 1.5;
        }
      }
    }
    
    return false; // Don't block other collision handling
  }
  
  double getDistanceTo(Vector2 targetPosition) {
    return position.distanceTo(targetPosition);
  }
  
  double getAngleTo(Vector2 targetPosition) {
    final diff = targetPosition - position;
    return math.atan2(diff.y, diff.x);
  }
  
  /// Set reference to inventory system for automatic pickup
  void setInventorySystem(InventorySystem inventorySystem) {
    _inventorySystem = inventorySystem;
  }
  
  /// Set reference to health system for damage and healing
  void setHealthSystem(HealthSystem healthSystem) {
    _healthSystem = healthSystem;
  }
  
  /// Take damage (for future NPC implementation)
  void takeDamage(double amount, {String? damageType, String? source}) {
    if (_healthSystem == null) {
      print('⚠️ WARNING: Health system not available for damage');
      return;
    }
    
    _healthSystem!.takeDamage(amount, damageType: damageType, source: source);
  }
  
  /// Get current health status (for UI and debugging)
  double getCurrentHealth() {
    return _healthSystem?.currentHealth ?? 100.0;
  }
  
  /// Check if player is alive
  bool isAlive() {
    return _healthSystem?.isAlive ?? true;
  }
  
  /// Check for nearby items and automatically pick them up
  void _checkForItemPickup() {
    if (_inventorySystem == null || parent == null) {
      if (_inventorySystem == null) {
        print('⚠️ DEBUG: Inventory system is null');
      }
      if (parent == null) {
        print('⚠️ DEBUG: Player parent is null');
      }
      return;
    }
    
    // Find all item objects in the parent (level)
    final items = parent!.children.whereType<GameObject>()
        .where((obj) => (obj.type == GameObjectType.item || obj.type == GameObjectType.healthArtifact) && 
                       obj.isActive && 
                       !obj.isPickedUp);
    
    if (items.isNotEmpty && DateTime.now().millisecondsSinceEpoch % 2000 < 16) { // Debug every ~2 seconds
      print('🔍 DEBUG: Found ${items.length} items near player');
      for (final item in items) {
        final distance = position.distanceTo(item.position + item.size / 2);
        print('  - ${item.name} at distance ${distance.toStringAsFixed(1)} (pickup radius: ${item.pickupRadius})');
      }
    }
    
    for (final item in items) {
      // Calculate distance to item center
      final itemCenter = item.position + item.size / 2;
      final distance = position.distanceTo(itemCenter);
      
      // Check if within this item's specific pickup radius
      if (distance <= item.pickupRadius) {
        print('🎯 DEBUG: Player within pickup range of "${item.name}" (distance: ${distance.toStringAsFixed(1)}, radius: ${item.pickupRadius})');
        
        // Create unique ID for this item to prevent duplicate pickups
        final itemId = '${item.name}_${item.position.x.toInt()}_${item.position.y.toInt()}';
        
        if (!_inventorySystem!.isItemPickedUp(itemId)) {
          print('🎯 DEBUG: Attempting to pick up "${item.name}"');
          
          // Handle different item types
          if (item.type == GameObjectType.healthArtifact) {
            _processHealthArtifact(item, itemId, distance);
          } else {
            _processRegularItem(item, itemId, distance);
          }
        } else {
          print('⚠️ DEBUG: Item "${item.name}" already picked up');
        }
      }
    }
  }
  
  /// Process regular item pickup
  void _processRegularItem(GameObject item, String itemId, double distance) {
    // Trigger automatic pickup for regular items
    _inventorySystem!.markItemPickedUp(itemId);
    _inventorySystem!.addItem(
      item.name, 
      description: item.description,
      atmosphericDescription: item.atmosphericDescription,
    );
    
    // Mark item as picked up and remove from game world
    item.isPickedUp = true;
    item.isActive = false;
    item.removeFromParent();
    
    print('🎯 PICKUP: Player automatically picked up "${item.name}" at distance ${distance.toStringAsFixed(1)}');
  }
  
  /// Process health artifact pickup
  void _processHealthArtifact(GameObject item, String itemId, double distance) {
    if (_healthSystem == null) {
      print('⚠️ WARNING: Health system not available for health artifact pickup');
      return;
    }
    
    // Mark as picked up to prevent duplicate processing
    _inventorySystem!.markItemPickedUp(itemId);
    
    // Process through health system
    _healthSystem!.processHealthArtifact(
      item.name,
      item.healingAmount,
      item.atmosphericDescription ?? item.description,
    );
    
    // Mark item as picked up and remove from game world
    item.isPickedUp = true;
    item.isActive = false;
    item.removeFromParent();
    
    print('❤️ PICKUP: Player automatically picked up health artifact "${item.name}" (+${item.healingAmount.toInt()} health) at distance ${distance.toStringAsFixed(1)}');
  }
}