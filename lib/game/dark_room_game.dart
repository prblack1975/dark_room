import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'components/player.dart';
import 'components/stable_debug_overlay.dart';
import 'components/wall_occlusion_debug.dart';
import 'components/pickup_debug_overlay.dart';
import 'levels/level.dart';
import 'levels/tutorial_level.dart';
import 'levels/escape_room_level.dart';
import 'levels/menu_level.dart';
import 'systems/health_system.dart';
import 'ui/game_hud.dart';
import 'ui/settings_config.dart';

class DarkRoomGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Player player;
  late Level currentLevel;
  late StableDebugOverlay debugOverlay;
  late WallOcclusionDebug wallOcclusionDebug;
  late PickupDebugOverlay pickupDebugOverlay;
  late GameHUD gameHUD;
  late SettingsConfig settings;
  late HealthSystem healthSystem;
  
  bool debugMode = false;
  bool isGamePaused = false;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Set up camera
    camera.viewfinder.visibleGameSize = Vector2(800, 600);
    
    // Initialize settings
    settings = SettingsConfig();
    
    // Initialize player
    player = Player(position: Vector2(400, 300));
    
    // Initialize health system
    healthSystem = HealthSystem();
    await add(healthSystem);
    
    // Connect player to health system
    player.setHealthSystem(healthSystem);
    
    // Initialize debug overlays
    debugOverlay = StableDebugOverlay();
    wallOcclusionDebug = WallOcclusionDebug();
    pickupDebugOverlay = PickupDebugOverlay();
    
    // Initialize HUD
    gameHUD = GameHUD();
    await add(gameHUD);
    
    // Load first level (menu)
    await loadLevel(MenuLevel());
  }
  
  Future<void> loadLevel(Level level) async {
    // Remove previous level if exists
    if (children.whereType<Level>().isNotEmpty) {
      removeAll(children.whereType<Level>());
    }
    
    currentLevel = level;
    await add(currentLevel);
    
    // Add player to the level
    await currentLevel.add(player);
    
    // Set player spawn position
    player.position = currentLevel.playerSpawn;
    
    // Initialize player systems now that player is in the level
    await currentLevel.initializePlayerSystems();
    
    // Add debug overlays if in debug mode
    if (debugMode) {
      await currentLevel.add(debugOverlay);
    }
    
    // Always add wall occlusion debug (it manages its own visibility)
    await currentLevel.add(wallOcclusionDebug);
    
    // Always add pickup debug overlay (it manages its own visibility)
    await currentLevel.add(pickupDebugOverlay);
    
    // Connect HUD to level systems
    gameHUD.connectSystems(
      inventorySystem: currentLevel.inventorySystem,
      narrationSystem: currentLevel.narrationSystem,
      healthSystem: healthSystem,
    );
    
    // Connect health system to narration system
    healthSystem.setNarrationSystem(currentLevel.narrationSystem);
    
    // Reset health for new level (except for menu level)
    if (level is! MenuLevel) {
      healthSystem.resetHealth();
    }
  }
  
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Toggle debug mode with F3 key only
    if (event is KeyDownEvent) {
      if (keysPressed.contains(LogicalKeyboardKey.f3)) {
        toggleDebugMode();
        return KeyEventResult.handled;
      }
      
      // Return to menu with ESC or M key
      if (keysPressed.contains(LogicalKeyboardKey.escape) ||
          keysPressed.contains(LogicalKeyboardKey.keyM)) {
        if (currentLevel is! MenuLevel) {
          loadLevel(MenuLevel());
        }
        return KeyEventResult.handled;
      }
      
      // Toggle wall occlusion debug with O key
      if (keysPressed.contains(LogicalKeyboardKey.keyO)) {
        wallOcclusionDebug.toggle();
        return KeyEventResult.handled;
      }
      
      // Pickup debug controls
      if (keysPressed.contains(LogicalKeyboardKey.keyP)) {
        pickupDebugOverlay.togglePickupRanges();
        return KeyEventResult.handled;
      }
      
      if (keysPressed.contains(LogicalKeyboardKey.keyI)) {
        pickupDebugOverlay.toggleInventoryInfo();
        return KeyEventResult.handled;
      }
      
      if (keysPressed.contains(LogicalKeyboardKey.keyL)) {
        pickupDebugOverlay.toggleDistanceInfo();
        return KeyEventResult.handled;
      }
      
      // Enable all pickup debug with U key
      if (keysPressed.contains(LogicalKeyboardKey.keyU)) {
        pickupDebugOverlay.enableAllDebug();
        return KeyEventResult.handled;
      }
      
      // HUD control keys
      if (keysPressed.contains(LogicalKeyboardKey.tab)) {
        gameHUD.handleKeyboardInput('tab');
        return KeyEventResult.handled;
      }
      
      if (keysPressed.contains(LogicalKeyboardKey.keyN)) {
        gameHUD.handleKeyboardInput('n');
        return KeyEventResult.handled;
      }
      
      if (keysPressed.contains(LogicalKeyboardKey.keyH)) {
        gameHUD.handleKeyboardInput('h');
        return KeyEventResult.handled;
      }
      
      if (keysPressed.contains(LogicalKeyboardKey.keyU)) {
        gameHUD.handleKeyboardInput('u');
        return KeyEventResult.handled;
      }
      
      if (keysPressed.contains(LogicalKeyboardKey.f4)) {
        gameHUD.handleKeyboardInput('f4');
        return KeyEventResult.handled;
      }
      
      // Health debug keys
      if (keysPressed.contains(LogicalKeyboardKey.digit1)) {
        gameHUD.handleKeyboardInput('1');
        return KeyEventResult.handled;
      }
      
      if (keysPressed.contains(LogicalKeyboardKey.digit2)) {
        gameHUD.handleKeyboardInput('2');
        return KeyEventResult.handled;
      }
      
      if (keysPressed.contains(LogicalKeyboardKey.digit3)) {
        gameHUD.handleKeyboardInput('3');
        return KeyEventResult.handled;
      }
      
      if (keysPressed.contains(LogicalKeyboardKey.digit4)) {
        gameHUD.handleKeyboardInput('4');
        return KeyEventResult.handled;
      }
      
      if (keysPressed.contains(LogicalKeyboardKey.digit5)) {
        gameHUD.handleKeyboardInput('5');
        return KeyEventResult.handled;
      }
      
      if (keysPressed.contains(LogicalKeyboardKey.digit6)) {
        gameHUD.handleKeyboardInput('6');
        return KeyEventResult.handled;
      }
      
    }
    
    // Pass movement keys to player
    player.updateMovement(keysPressed);
    
    // Return handled instead of ignored to prevent system audio feedback
    return KeyEventResult.handled;
  }
  
  void toggleDebugMode() {
    debugMode = !debugMode;
    
    if (debugMode) {
      if (!currentLevel.children.contains(debugOverlay)) {
        currentLevel.add(debugOverlay);
      }
      // Debug overlay is now stable
    } else {
      if (currentLevel.children.contains(debugOverlay)) {
        currentLevel.remove(debugOverlay);
      }
    }
  }
  
  void togglePause() {
    isGamePaused = !isGamePaused;
    if (isGamePaused) {
      pauseEngine();
    } else {
      resumeEngine();
    }
  }
  
  void completeLevel() {
    // Return to menu after level completion
    loadLevel(MenuLevel());
  }
  
  @override
  void render(Canvas canvas) {
    // Fill background with black
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.black,
    );
    
    super.render(canvas);
  }
}