import 'package:flame/components.dart';
import '../audio/asset_audio_player.dart';
import 'narration_system.dart';

/// Manages player inventory for the Dark Room game
/// 
/// Features:
/// - Level-specific inventory storage
/// - Automatic item tracking
/// - Audio feedback for pickup events
/// - No capacity limits per game design
class InventorySystem extends Component {
  static const double pickupRadius = 35.0; // Pickup range in pixels
  
  final List<String> _items = [];
  final List<String> _pickedUpItemIds = []; // Track unique item IDs to prevent duplicate pickups
  late AssetAudioPlayer _audioPlayer;
  
  // Reference to narration system
  NarrationSystem? _narrationSystem;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    _audioPlayer = AssetAudioPlayer();
  }
  
  /// Set reference to narration system
  void setNarrationSystem(NarrationSystem narrationSystem) {
    _narrationSystem = narrationSystem;
  }
  
  /// Get current inventory items
  List<String> get items => List.unmodifiable(_items);
  
  /// Check if inventory contains a specific item
  bool hasItem(String itemName) {
    return _items.contains(itemName);
  }
  
  /// Add item to inventory (called by automatic pickup system)
  void addItem(String itemName, {String? description, String? atmosphericDescription}) {
    if (!_items.contains(itemName)) {
      _items.add(itemName);
      _playPickupFeedback(itemName, description, atmosphericDescription);
      print('📦 INVENTORY: Added item "$itemName" to inventory (Total: ${_items.length})');
    }
  }
  
  /// Remove item from inventory
  void removeItem(String itemName) {
    if (_items.remove(itemName)) {
      print('📦 INVENTORY: Removed item "$itemName" from inventory (Total: ${_items.length})');
    }
  }
  
  /// Clear all items (when changing levels)
  void clearInventory() {
    _items.clear();
    _pickedUpItemIds.clear();
    print('📦 INVENTORY: Cleared all items for new level');
  }
  
  /// Track item as picked up to prevent duplicate pickups
  void markItemPickedUp(String itemId) {
    if (!_pickedUpItemIds.contains(itemId)) {
      _pickedUpItemIds.add(itemId);
    }
  }
  
  /// Check if item has already been picked up
  bool isItemPickedUp(String itemId) {
    return _pickedUpItemIds.contains(itemId);
  }
  
  /// Play audio feedback and queue narration for item pickup
  void _playPickupFeedback(String itemName, String? description, String? atmosphericDescription) {
    // Play pickup sound effect
    _audioPlayer.playPickupSound();
    
    // Use narration system if available
    if (_narrationSystem != null) {
      // Prefer atmospheric description, fallback to regular description
      final useDescription = atmosphericDescription ?? description;
      if (useDescription != null && useDescription.isNotEmpty) {
        _narrationSystem!.narrateItemPickup(itemName, useDescription);
      } else {
        _narrationSystem!.narrate('Picked up $itemName');
      }
    } else {
      // Fallback to print for debugging
      final useDescription = atmosphericDescription ?? description;
      final narrationText = useDescription != null && useDescription.isNotEmpty 
          ? 'Picked up $itemName. $useDescription'
          : 'Picked up $itemName';
      print('🗣️ NARRATION: "$narrationText"');
    }
  }
  
  /// Get debug info about current inventory state
  Map<String, dynamic> getDebugInfo() {
    return {
      'itemCount': _items.length,
      'items': _items,
      'pickedUpIds': _pickedUpItemIds,
      'hasNarrationSystem': _narrationSystem != null,
    };
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    // Inventory system is mostly event-driven, minimal update logic needed
  }
}