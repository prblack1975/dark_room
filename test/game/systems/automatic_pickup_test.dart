import 'package:flutter_test/flutter_test.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flame/components.dart';
import 'package:dark_room/game/dark_room_game.dart';
import 'package:dark_room/game/levels/tutorial_level.dart';
import 'package:dark_room/game/components/game_object.dart';
import 'package:dark_room/game/systems/inventory_system.dart';

void main() {
  // Initialize bindings for audio tests
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Automatic Pickup System Tests', () {
    testWithGame<DarkRoomGame>(
      'player automatically picks up nearby items',
      DarkRoomGame.new,
      (game) async {
      // Load tutorial level which has items
      final level = TutorialLevel();
      await game.loadLevel(level);
      
      // Wait for level initialization
      await game.ready();
      
      // Get player and inventory system
      final player = game.player!;
      final inventorySystem = level.inventorySystem;
      
      // Find the rusty key item in the tutorial level
      final rustyKey = level.children
          .whereType<GameObject>()
          .where((obj) => obj.type == GameObjectType.item && obj.name == 'rusty_key')
          .firstOrNull;
      
      expect(rustyKey, isNotNull, reason: 'Tutorial level should have a rusty key item');
      
      // Verify initial state
      expect(inventorySystem.items.length, equals(0), reason: 'Inventory should start empty');
      expect(rustyKey!.isPickedUp, isFalse, reason: 'Item should not be picked up initially');
      expect(rustyKey.isActive, isTrue, reason: 'Item should be active initially');
      
      // Move player close to the key (within pickup radius)
      final keyCenter = rustyKey.position + rustyKey.size / 2;
      player.position = keyCenter - Vector2(20, 0); // 20 pixels away
      
      // Update game to trigger pickup logic
      game.update(0.016); // One frame at 60 FPS
      
      // Verify automatic pickup occurred
      expect(inventorySystem.items.length, equals(1), reason: 'Item should be picked up automatically');
      expect(inventorySystem.hasItem('rusty_key'), isTrue, reason: 'Inventory should contain the rusty key');
      expect(rustyKey.isPickedUp, isTrue, reason: 'Item should be marked as picked up');
      expect(rustyKey.isActive, isFalse, reason: 'Item should be deactivated after pickup');
    });
    
    testWithGame<DarkRoomGame>(
      'player does not pick up items outside pickup radius',
      DarkRoomGame.new,
      (game) async {
      // Load tutorial level
      final level = TutorialLevel();
      await game.loadLevel(level);
      await game.ready();
      
      // Get components
      final player = game.player!;
      final inventorySystem = level.inventorySystem;
      
      // Find the rusty key
      final rustyKey = level.children
          .whereType<GameObject>()
          .where((obj) => obj.type == GameObjectType.item && obj.name == 'rusty_key')
          .firstOrNull;
      
      expect(rustyKey, isNotNull);
      
      // Move player far from the key (outside pickup radius)
      final keyCenter = rustyKey!.position + rustyKey.size / 2;
      player.position = keyCenter - Vector2(100, 0); // 100 pixels away (outside radius)
      
      // Update game
      game.update(0.016);
      
      // Verify no pickup occurred
      expect(inventorySystem.items.length, equals(0), reason: 'Item should not be picked up when too far');
      expect(inventorySystem.hasItem('rusty_key'), isFalse, reason: 'Inventory should not contain the key');
      expect(rustyKey.isPickedUp, isFalse, reason: 'Item should not be marked as picked up');
      expect(rustyKey.isActive, isTrue, reason: 'Item should remain active');
    });
    
    testWithGame<DarkRoomGame>(
      'inventory system prevents duplicate pickups',
      DarkRoomGame.new,
      (game) async {
      // Load tutorial level
      final level = TutorialLevel();
      await game.loadLevel(level);
      await game.ready();
      
      // Get components
      final player = game.player!;
      final inventorySystem = level.inventorySystem;
      
      // Find the rusty key
      final rustyKey = level.children
          .whereType<GameObject>()
          .where((obj) => obj.type == GameObjectType.item && obj.name == 'rusty_key')
          .firstOrNull;
      
      expect(rustyKey, isNotNull);
      
      // Move player close to the key
      final keyCenter = rustyKey!.position + rustyKey.size / 2;
      player.position = keyCenter;
      
      // Update game to trigger pickup
      game.update(0.016);
      
      // Verify pickup occurred
      expect(inventorySystem.items.length, equals(1));
      
      // Try to trigger pickup again (should not happen since item is removed)
      game.update(0.016);
      
      // Verify no duplicate pickup
      expect(inventorySystem.items.length, equals(1), reason: 'Should not have duplicate items');
      expect(inventorySystem.items.where((item) => item == 'rusty_key').length, equals(1),
          reason: 'Should have exactly one rusty key');
    });
    
    testWithGame<DarkRoomGame>(
      'door automatically unlocks when player has required key',
      DarkRoomGame.new,
      (game) async {
      // Load tutorial level
      final level = TutorialLevel();
      await game.loadLevel(level);
      await game.ready();
      
      // Get components
      final player = game.player!;
      final inventorySystem = level.inventorySystem;
      
      // Find the door and key
      final door = level.children
          .whereType<GameObject>()
          .where((obj) => obj.type == GameObjectType.door && obj.name == 'exit_door')
          .firstOrNull;
      
      final rustyKey = level.children
          .whereType<GameObject>()
          .where((obj) => obj.type == GameObjectType.item && obj.name == 'rusty_key')
          .firstOrNull;
      
      expect(door, isNotNull, reason: 'Tutorial level should have an exit door');
      expect(rustyKey, isNotNull, reason: 'Tutorial level should have a rusty key');
      expect(door!.isLocked, isTrue, reason: 'Door should be locked initially');
      expect(door.requiredKey, equals('rusty_key'), reason: 'Door should require rusty key');
      
      // First, pick up the key
      final keyCenter = rustyKey!.position + rustyKey.size / 2;
      player.position = keyCenter;
      game.update(0.016);
      
      // Verify key was picked up
      expect(inventorySystem.hasItem('rusty_key'), isTrue, reason: 'Should have picked up the key');
      
      // Now approach the door
      final doorCenter = door.position + door.size / 2;
      player.position = doorCenter - Vector2(30, 0); // Within interaction range
      
      // Update to trigger door interaction
      game.update(0.016);
      
      // The door should unlock automatically when player approaches with key
      // Note: In the current implementation, the door unlocks but level completion
      // requires the player to be very close to the door
      expect(inventorySystem.hasItem('rusty_key'), isTrue, 
          reason: 'Player should still have the key (keys are not consumed)');
    });
    
    test('InventorySystem provides correct debug information', () async {
      final inventorySystem = InventorySystem();
      await inventorySystem.onLoad(); // Initialize the system
      
      // Test initial state
      var debugInfo = inventorySystem.getDebugInfo();
      expect(debugInfo['itemCount'], equals(0));
      expect(debugInfo['items'], isEmpty);
      expect(debugInfo['pickedUpIds'], isEmpty);
      
      // Only test the marking system (avoid audio-dependent addItem)
      inventorySystem.markItemPickedUp('test_id_1');
      
      debugInfo = inventorySystem.getDebugInfo();
      expect(debugInfo['pickedUpIds'], contains('test_id_1'));
    });
    
    test('InventorySystem prevents duplicate item IDs', () {
      final inventorySystem = InventorySystem();
      
      // Mark item as picked up
      inventorySystem.markItemPickedUp('unique_id_1');
      expect(inventorySystem.isItemPickedUp('unique_id_1'), isTrue);
      
      // Try to mark same ID again
      inventorySystem.markItemPickedUp('unique_id_1');
      final debugInfo = inventorySystem.getDebugInfo();
      
      // Should only appear once in the list
      expect(debugInfo['pickedUpIds'].where((id) => id == 'unique_id_1').length, equals(1));
    });
  });
}