import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dark_room/game/levels/tutorial_level.dart';
import 'package:dark_room/game/components/wall.dart';
import 'package:dark_room/game/components/game_object.dart';

void main() {
  group('TutorialLevel (Simple Tests)', () {
    testWithFlameGame('initializes with correct basic properties', (game) async {
      final level = TutorialLevel();
      
      expect(level.name, equals('Tutorial'));
      expect(level.description, equals('Learn the basics of movement and interaction'));
      expect(level.playerSpawn, equals(Vector2(100, 300)));
      expect(level.inventory, isEmpty);
    });

    testWithFlameGame('can create game objects manually', (game) async {
      final key = GameObject(
        type: GameObjectType.item,
        name: 'test_key',
        description: 'A test key',
        position: Vector2(100, 100),
      );
      
      expect(key.name, equals('test_key'));
      expect(key.type, equals(GameObjectType.item));
      expect(key.isPickedUp, isFalse);
      expect(key.isActive, isTrue);
    });

    testWithFlameGame('can create walls manually', (game) async {
      final wall = Wall(
        position: Vector2(50, 50),
        size: Vector2(100, 20),
      );
      
      expect(wall.position, equals(Vector2(50, 50)));
      expect(wall.size, equals(Vector2(100, 20)));
    });
  });

  group('TutorialLevel Interactions (Simple)', () {
    testWithFlameGame('item interaction works without audio', (game) async {
      final key = GameObject(
        type: GameObjectType.item,
        name: 'test_key',
        description: 'A test key',
        position: Vector2(100, 100),
      );
      
      final inventory = <String>[];
      
      // Initially not picked up
      expect(key.isPickedUp, isFalse);
      expect(key.canInteract(inventory), isTrue);
      
      // Interact with key
      key.interact(inventory);
      expect(key.isPickedUp, isTrue);
      
      // Add to inventory manually (as the level would do)
      inventory.add(key.name);
      expect(inventory, contains('test_key'));
    });

    testWithFlameGame('door interaction works without audio', (game) async {
      final door = GameObject(
        type: GameObjectType.door,
        name: 'test_door',
        description: 'A test door',
        position: Vector2(100, 100),
        requiredKey: 'test_key',
      );
      
      final inventory = <String>[];
      
      // Initially locked and can't interact without key
      expect(door.isLocked, isTrue);
      expect(door.canInteract(inventory), isFalse);
      
      // Add key to inventory
      inventory.add('test_key');
      expect(door.canInteract(inventory), isTrue);
      
      // Interact with door
      door.interact(inventory);
      expect(door.isLocked, isFalse);
    });
  });
}