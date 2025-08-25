import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../systems/inventory_system.dart';
import '../systems/narration_system.dart';
import '../systems/health_system.dart';
import 'inventory_display.dart';
import 'narration_display.dart';
import 'health_display.dart';
import 'settings_config.dart';

/// Main HUD component for Dark Room game
/// 
/// Features:
/// - Manages all UI sub-components
/// - Handles UI configuration and settings
/// - Maintains minimal visibility aesthetic
/// - Provides debug UI functionality
/// - Coordinates between different UI elements
class GameHUD extends Component {
  late InventoryDisplay inventoryDisplay;
  late NarrationDisplay narrationDisplay;
  late HealthDisplay healthDisplay;
  late SettingsConfig settings;
  
  // Debug UI components
  late TextPaint _debugTextPaint;
  bool _showDebugUI = false;
  
  // References to game systems
  InventorySystem? _inventorySystem;
  NarrationSystem? _narrationSystem;
  HealthSystem? _healthSystem;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    settings = SettingsConfig();
    
    // Initialize UI components
    inventoryDisplay = InventoryDisplay();
    narrationDisplay = NarrationDisplay();
    healthDisplay = HealthDisplay();
    
    // Add components to HUD
    add(inventoryDisplay);
    add(narrationDisplay);
    add(healthDisplay);
    
    _initializeDebugTextPaint();
    
    print('🖥️ GAME HUD: Initialized with minimal visibility design');
  }
  
  void _initializeDebugTextPaint() {
    _debugTextPaint = TextPaint(
      style: TextStyle(
        color: Colors.yellow.withOpacity(0.8),
        fontSize: 10,
        fontFamily: 'monospace',
      ),
    );
  }
  
  /// Connect HUD to game systems
  void connectSystems({
    required InventorySystem inventorySystem,
    required NarrationSystem narrationSystem,
    required HealthSystem healthSystem,
  }) {
    _inventorySystem = inventorySystem;
    _narrationSystem = narrationSystem;
    _healthSystem = healthSystem;
    
    // Connect sub-components
    inventoryDisplay.setInventorySystem(inventorySystem);
    narrationDisplay.setNarrationSystem(narrationSystem);
    healthDisplay.setHealthSystem(healthSystem);
    
    print('🖥️ GAME HUD: Connected to game systems');
  }
  
  /// Handle keyboard shortcuts for UI toggles
  void handleKeyboardInput(String key) {
    switch (key.toLowerCase()) {
      case 'tab':
        settings.toggleInventoryDisplay();
        inventoryDisplay.refresh();
        break;
      case 'n':
        settings.toggleNarrationText();
        break;
      case 'h':
        settings.toggleHealthDisplay();
        healthDisplay.refresh();
        break;
      case 'u':
        settings.toggleMinimalHUDMode();
        _refreshAllComponents();
        break;
      case 'f4':
        _toggleDebugUI();
        break;
      case '1':
        _debugSetHealth(25.0); // Critical health for testing
        break;
      case '2':
        _debugSetHealth(50.0); // Low health for testing
        break;
      case '3':
        _debugSetHealth(75.0); // Medium health for testing
        break;
      case '4':
        _debugSetHealth(100.0); // Full health for testing
        break;
      case '5':
        _debugTakeDamage(15.0); // Test damage
        break;
      case '6':
        _debugRestoreHealth(25.0); // Test healing
        break;
    }
  }
  
  void _toggleDebugUI() {
    _showDebugUI = !_showDebugUI;
    print('🖥️ GAME HUD: Debug UI ${_showDebugUI ? 'enabled' : 'disabled'}');
  }
  
  /// Debug: Set health to specific value
  void _debugSetHealth(double health) {
    if (_healthSystem == null) {
      print('⚠️ DEBUG: Health system not available');
      return;
    }
    
    _healthSystem!.setHealth(health);
    print('🔧 DEBUG: Set health to ${health.toInt()}');
  }
  
  /// Debug: Take damage
  void _debugTakeDamage(double amount) {
    if (_healthSystem == null) {
      print('⚠️ DEBUG: Health system not available');
      return;
    }
    
    _healthSystem!.takeDamage(amount, source: 'debug command');
    print('🔧 DEBUG: Took ${amount.toInt()} damage');
  }
  
  /// Debug: Restore health
  void _debugRestoreHealth(double amount) {
    if (_healthSystem == null) {
      print('⚠️ DEBUG: Health system not available');
      return;
    }
    
    _healthSystem!.restoreHealth(amount, source: 'debug command');
    print('🔧 DEBUG: Restored ${amount.toInt()} health');
  }
  
  void _refreshAllComponents() {
    inventoryDisplay.refresh();
    healthDisplay.refresh();
    // Refresh other components as needed
    print('🖥️ GAME HUD: Refreshed all components');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update display positions if needed
    if (parent != null && parent is FlameGame) {
      final game = parent as FlameGame;
      narrationDisplay.updatePosition(gameSize: game.size);
      healthDisplay.updatePosition(gameSize: game.size);
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Render debug UI if enabled
    if (_showDebugUI && settings.debugInfoVisible) {
      _renderDebugUI(canvas);
    }
  }
  
  void _renderDebugUI(Canvas canvas) {
    final debugInfo = getDebugInfo();
    var yOffset = 300.0;
    const lineHeight = 12.0;
    
    _debugTextPaint.render(
      canvas,
      '=== DARK ROOM HUD DEBUG ===',
      Vector2(10, yOffset),
    );
    yOffset += lineHeight * 2;
    
    // Settings info
    _debugTextPaint.render(
      canvas,
      'SETTINGS:',
      Vector2(10, yOffset),
    );
    yOffset += lineHeight;
    
    final settings = debugInfo['settings'] as Map<String, dynamic>;
    for (final entry in settings.entries) {
      _debugTextPaint.render(
        canvas,
        '  ${entry.key}: ${entry.value}',
        Vector2(10, yOffset),
      );
      yOffset += lineHeight;
    }
    
    yOffset += lineHeight;
    
    // Component info
    _debugTextPaint.render(
      canvas,
      'COMPONENTS:',
      Vector2(10, yOffset),
    );
    yOffset += lineHeight;
    
    final components = debugInfo['components'] as Map<String, dynamic>;
    for (final entry in components.entries) {
      _debugTextPaint.render(
        canvas,
        '  ${entry.key}: ${entry.value}',
        Vector2(10, yOffset),
      );
      yOffset += lineHeight;
    }
    
    // Keybind help
    yOffset += lineHeight;
    _debugTextPaint.render(
      canvas,
      'KEYBINDS: TAB=inventory, N=narration, H=health, U=HUD mode, F4=debug',
      Vector2(10, yOffset),
    );
    yOffset += lineHeight;
    _debugTextPaint.render(
      canvas,
      'HEALTH DEBUG: 1=25%, 2=50%, 3=75%, 4=100%, 5=damage, 6=heal',
      Vector2(10, yOffset),
    );
  }
  
  /// Get comprehensive debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'settings': {
        'inventoryVisible': settings.inventoryDisplayVisible,
        'narrationVisible': settings.narrationTextVisible,
        'minimalHUD': settings.minimalHUDMode,
        'hudOpacity': settings.hudOpacity,
        'debugUIVisible': _showDebugUI,
      },
      'components': {
        'inventoryDisplay': inventoryDisplay.getDebugInfo(),
        'narrationDisplay': narrationDisplay.getDebugInfo(),
        'healthDisplay': healthDisplay.getDebugInfo(),
      },
      'systems': {
        'hasInventorySystem': _inventorySystem != null,
        'hasNarrationSystem': _narrationSystem != null,
        'hasHealthSystem': _healthSystem != null,
        'inventoryItems': _inventorySystem?.items.length ?? 0,
        'narrationQueue': _narrationSystem?.queueLength ?? 0,
        'currentHealth': _healthSystem?.currentHealth ?? 100,
      },
    };
  }
  
  /// Programmatically show narration text (for testing)
  void showTestNarration(String text) {
    narrationDisplay.showText(text);
    print('🖥️ GAME HUD: Showing test narration: "$text"');
  }
  
  /// Get current UI visibility status
  Map<String, bool> getUIVisibilityStatus() {
    return {
      'inventory': settings.inventoryDisplayVisible,
      'narration': settings.narrationTextVisible,
      'debug': _showDebugUI,
      'minimalMode': settings.minimalHUDMode,
    };
  }
  
  /// Update HUD size when parent changes
  void updateSize(Vector2 newSize) {
    // Update component positions based on new size
    narrationDisplay.updatePosition(gameSize: newSize);
    healthDisplay.updatePosition(gameSize: newSize);
    print('🖥️ GAME HUD: Updated size to $newSize');
  }
  
  /// Force refresh all UI elements
  void refresh() {
    _refreshAllComponents();
  }
  
  /// Show quick status message (for debugging or feedback)
  void showStatusMessage(String message, {double duration = 3.0}) {
    narrationDisplay.showText('Status: $message', duration: duration);
  }
}