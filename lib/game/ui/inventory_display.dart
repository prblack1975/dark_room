import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../systems/inventory_system.dart';
import '../utils/game_logger.dart';
import 'settings_config.dart';

/// Minimal inventory display component for Dark Room game
/// 
/// Features:
/// - Dark grey, barely visible text per game design
/// - Real-time inventory updates
/// - Configurable visibility
/// - Non-intrusive corner positioning
/// - Follows "minimal HUD" aesthetic
class InventoryDisplay extends Component {
  late final GameCategoryLogger _logger;
  InventorySystem? _inventorySystem;
  late SettingsConfig _settings;
  late TextPaint _textPaint;
  late TextPaint _headerPaint;
  
  final Vector2 _position = Vector2(20, 20); // Top-left corner
  final double _lineHeight = 16.0;
  final List<String> _displayItems = [];
  
  bool _needsUpdate = true;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    gameLogger.initialize();
    _logger = gameLogger.ui;
    _settings = SettingsConfig();
    _initializeTextPaints();
    _logger.info('📋 INVENTORY DISPLAY: Initialized');
  }
  
  void _initializeTextPaints() {
    // Very dark grey color for "barely visible" design
    final textColor = Color.fromARGB(
      (255 * _settings.hudOpacity).round(),
      120, 120, 120, // Dark grey
    );
    
    _textPaint = TextPaint(
      style: TextStyle(
        color: textColor,
        fontSize: _settings.inventoryFontSize,
        fontFamily: 'monospace',
      ),
    );
    
    _headerPaint = TextPaint(
      style: TextStyle(
        color: textColor,
        fontSize: _settings.inventoryFontSize + 2,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  /// Set the inventory system to monitor
  void setInventorySystem(InventorySystem inventorySystem) {
    _inventorySystem = inventorySystem;
    _updateDisplayItems();
    _logger.info('📋 INVENTORY DISPLAY: Connected to inventory system');
  }
  
  /// Update the displayed inventory items
  void _updateDisplayItems() {
    if (_inventorySystem == null) return;
    
    _displayItems.clear();
    _displayItems.addAll(_inventorySystem!.items);
    _needsUpdate = true;
  }
  
  /// Force refresh the display
  void refresh() {
    _updateDisplayItems();
    _initializeTextPaints(); // Update text style if settings changed
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Check if inventory has changed
    if (_inventorySystem != null && _inventorySystem!.items.length != _displayItems.length) {
      _updateDisplayItems();
    }
    
    // Update text paints if settings changed
    if (_needsUpdate) {
      _initializeTextPaints();
      _needsUpdate = false;
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Don't render if inventory display is disabled
    if (!_settings.inventoryDisplayVisible) return;
    
    // Don't render if minimal HUD mode is disabled and opacity is too low
    if (!_settings.minimalHUDMode && _settings.hudOpacity < 0.1) return;
    
    final startY = _position.y;
    var currentY = startY;
    
    // Render header
    _headerPaint.render(
      canvas,
      'INVENTORY',
      Vector2(_position.x, currentY),
    );
    currentY += _lineHeight + 4;
    
    // Render items or empty message
    if (_displayItems.isEmpty) {
      _textPaint.render(
        canvas,
        '(empty)',
        Vector2(_position.x + 4, currentY),
      );
    } else {
      for (int i = 0; i < _displayItems.length; i++) {
        final item = _displayItems[i];
        _textPaint.render(
          canvas,
          '• $item',
          Vector2(_position.x + 4, currentY),
        );
        currentY += _lineHeight;
      }
    }
    
    // Render item count
    currentY += 4;
    _textPaint.render(
      canvas,
      'Items: ${_displayItems.length}',
      Vector2(_position.x, currentY),
    );
  }
  
  /// Get debug information about the display
  Map<String, dynamic> getDebugInfo() {
    return {
      'visible': _settings.inventoryDisplayVisible,
      'itemCount': _displayItems.length,
      'position': {'x': _position.x, 'y': _position.y},
      'opacity': _settings.hudOpacity,
      'fontSize': _settings.inventoryFontSize,
      'minimalHUDMode': _settings.minimalHUDMode,
      'hasInventorySystem': _inventorySystem != null,
    };
  }
  
  /// Update position (for debugging or customization)
  void updatePosition(Vector2 newPosition) {
    _position.setFrom(newPosition);
    _logger.info('📋 INVENTORY DISPLAY: Position updated to $_position');
  }
  
  /// Get current display bounds (for UI layout calculations)
  Rect getDisplayBounds() {
    final itemCount = _displayItems.isEmpty ? 1 : _displayItems.length;
    final height = _lineHeight * (itemCount + 2) + 8; // Header + items + count + padding
    final width = 200.0; // Estimated width
    
    return Rect.fromLTWH(_position.x, _position.y, width, height);
  }
}