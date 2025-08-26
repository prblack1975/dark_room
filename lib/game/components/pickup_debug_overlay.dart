import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'game_object.dart';
import 'player.dart';
import '../systems/inventory_system.dart';
import '../utils/game_logger.dart';

/// Debug overlay for visualizing item pickup ranges and interactions
/// 
/// Features:
/// - Shows pickup radius around items
/// - Highlights items in pickup range
/// - Displays inventory contents
/// - Shows pickup distance measurements
class PickupDebugOverlay extends Component with HasGameReference {
  late final GameCategoryLogger _logger;
  bool _showPickupRanges = false;
  bool _showInventoryInfo = false;
  bool _showDistanceInfo = false;
  
  // Colors for debug visualization
  static const Color pickupRangeColor = Color(0x4400FF00); // Semi-transparent green
  static const Color activePickupColor = Color(0x8800FF00); // Brighter green
  static const Color itemColor = Color(0xFFFFFF00); // Yellow
  static const Color playerColor = Color(0xFF00FFFF); // Cyan
  
  @override
  void onLoad() async {
    super.onLoad();
    gameLogger.initialize();
    _logger = gameLogger.player;
  }

  @override
  void render(Canvas canvas) {
    if (!_showPickupRanges && !_showInventoryInfo && !_showDistanceInfo) return;
    
    // final camera = game.camera;
    // final viewfinder = camera.viewfinder;  // Reserved for camera-based calculations
    
    // Get components we need
    final player = _findPlayer();
    final items = _findItems();
    final inventorySystem = _findInventorySystem();
    
    if (_showPickupRanges && items.isNotEmpty) {
      _renderPickupRanges(canvas, items, player);
    }
    
    if (_showInventoryInfo && inventorySystem != null) {
      _renderInventoryInfo(canvas, inventorySystem);
    }
    
    if (_showDistanceInfo && player != null && items.isNotEmpty) {
      _renderDistanceInfo(canvas, player, items);
    }
  }
  
  /// Render pickup ranges around items
  void _renderPickupRanges(Canvas canvas, List<GameObject> items, Player? player) {
    for (final item in items) {
      if (item.isPickedUp || !item.isActive) continue;
      
      final itemCenter = item.position + item.size / 2;
      bool isInRange = false;
      
      if (player != null) {
        final distance = player.position.distanceTo(itemCenter);
        isInRange = distance <= item.pickupRadius;
      }
      
      // Draw pickup radius circle
      final paint = Paint()
        ..color = isInRange ? activePickupColor : pickupRangeColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(itemCenter.x, itemCenter.y),
        item.pickupRadius,
        paint,
      );
      
      // Draw item position marker
      final itemPaint = Paint()
        ..color = itemColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(itemCenter.x, itemCenter.y),
        5,
        itemPaint,
      );
      
      // Draw item name
      final textPainter = TextPainter(
        text: TextSpan(
          text: item.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(
        itemCenter.x - textPainter.width / 2,
        itemCenter.y - item.pickupRadius - 20,
      ));
    }
    
    // Draw player position if available
    if (player != null) {
      final playerPaint = Paint()
        ..color = playerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(
        Offset(player.position.x, player.position.y),
        player.size.x / 2,
        playerPaint,
      );
    }
  }
  
  /// Render inventory information
  void _renderInventoryInfo(Canvas canvas, InventorySystem inventorySystem) {
    final debugInfo = inventorySystem.getDebugInfo();
    
    // Create inventory text
    final inventoryText = 'INVENTORY DEBUG\n'
        'Items: ${debugInfo['itemCount']}\n'
        'Contents: ${debugInfo['items'].join(', ')}\n'
        'Picked Up IDs: ${debugInfo['pickedUpIds'].length}\n'
        'Has Narration: ${debugInfo['hasNarrationSystem']}';
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: inventoryText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Draw background
    final rect = Rect.fromLTWH(10, 10, textPainter.width + 20, textPainter.height + 20);
    final backgroundPaint = Paint()
      ..color = const Color(0xAA000000);
    
    canvas.drawRect(rect, backgroundPaint);
    
    // Draw text
    textPainter.paint(canvas, const Offset(20, 20));
  }
  
  /// Render distance information between player and items
  void _renderDistanceInfo(Canvas canvas, Player player, List<GameObject> items) {
    for (final item in items) {
      if (item.isPickedUp || !item.isActive) continue;
      
      final itemCenter = item.position + item.size / 2;
      final distance = player.position.distanceTo(itemCenter);
      
      // Draw line from player to item
      final linePaint = Paint()
        ..color = distance <= item.pickupRadius ? Colors.green : Colors.red
        ..strokeWidth = 1;
      
      canvas.drawLine(
        Offset(player.position.x, player.position.y),
        Offset(itemCenter.x, itemCenter.y),
        linePaint,
      );
      
      // Draw distance text at midpoint
      final midPoint = Offset(
        (player.position.x + itemCenter.x) / 2,
        (player.position.y + itemCenter.y) / 2,
      );
      
      final distanceText = distance.toStringAsFixed(1);
      final textPainter = TextPainter(
        text: TextSpan(
          text: distanceText,
          style: TextStyle(
            color: distance <= item.pickupRadius ? Colors.green : Colors.red,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(
        midPoint.dx - textPainter.width / 2,
        midPoint.dy - textPainter.height / 2,
      ));
    }
  }
  
  /// Find player component in the game
  Player? _findPlayer() {
    return game.world.children.whereType<Player>().firstOrNull;
  }
  
  /// Find all item GameObjects in the game
  List<GameObject> _findItems() {
    return game.world.children
        .expand((component) => component.children)
        .whereType<GameObject>()
        .where((obj) => obj.type == GameObjectType.item)
        .toList();
  }
  
  /// Find inventory system in the game
  InventorySystem? _findInventorySystem() {
    return game.world.children
        .expand((component) => component.children)
        .whereType<InventorySystem>()
        .firstOrNull;
  }
  
  /// Toggle pickup range visualization
  void togglePickupRanges() {
    _showPickupRanges = !_showPickupRanges;
    _logger.debug('🔍 DEBUG: Pickup ranges ${_showPickupRanges ? 'enabled' : 'disabled'}');
  }
  
  /// Toggle inventory information display
  void toggleInventoryInfo() {
    _showInventoryInfo = !_showInventoryInfo;
    _logger.debug('📦 DEBUG: Inventory info ${_showInventoryInfo ? 'enabled' : 'disabled'}');
  }
  
  /// Toggle distance information display
  void toggleDistanceInfo() {
    _showDistanceInfo = !_showDistanceInfo;
    _logger.debug('📏 DEBUG: Distance info ${_showDistanceInfo ? 'enabled' : 'disabled'}');
  }
  
  /// Enable all debug features
  void enableAllDebug() {
    _showPickupRanges = true;
    _showInventoryInfo = true;
    _showDistanceInfo = true;
    _logger.debug('🔍 DEBUG: All pickup debug features enabled');
  }
  
  /// Disable all debug features
  void disableAllDebug() {
    _showPickupRanges = false;
    _showInventoryInfo = false;
    _showDistanceInfo = false;
    _logger.debug('🔍 DEBUG: All pickup debug features disabled');
  }
  
  /// Get current debug state
  Map<String, bool> getDebugState() {
    return {
      'showPickupRanges': _showPickupRanges,
      'showInventoryInfo': _showInventoryInfo,
      'showDistanceInfo': _showDistanceInfo,
    };
  }
}