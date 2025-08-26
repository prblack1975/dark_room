import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dark_room/game/components/wall.dart';

void main() {
  group('Wall', () {
    testWithFlameGame('initializes with correct properties', (game) async {
      final position = Vector2(100, 200);
      final size = Vector2(50, 100);
      final wall = Wall(position: position, size: size);
      
      await game.ensureAdd(wall);

      expect(wall.position, equals(position));
      expect(wall.size, equals(size));
    });

    testWithFlameGame('adds rectangular hitbox on load', (game) async {
      final wall = Wall(
        position: Vector2(100, 100),
        size: Vector2(50, 75),
      );
      
      await game.ensureAdd(wall);

      // Check that a RectangleHitbox was added
      final hitboxes = wall.children.whereType<RectangleHitbox>();
      expect(hitboxes.length, equals(1));

      final hitbox = hitboxes.first;
      expect(hitbox.size, equals(Vector2(50, 75)));
    });

    testWithFlameGame('creates wall with custom dimensions', (game) async {
      final wall1 = Wall(
        position: Vector2(0, 0),
        size: Vector2(200, 20), // Horizontal wall
      );
      
      final wall2 = Wall(
        position: Vector2(100, 100),
        size: Vector2(20, 200), // Vertical wall
      );
      
      await game.ensureAddAll([wall1, wall2]);

      expect(wall1.size.x, equals(200));
      expect(wall1.size.y, equals(20));
      expect(wall2.size.x, equals(20));
      expect(wall2.size.y, equals(200));
    });

    testWithFlameGame('maintains collision properties', (game) async {
      final wall = Wall(
        position: Vector2(100, 100),
        size: Vector2(50, 50),
      );
      
      await game.ensureAdd(wall);

      // Verify wall has collision capabilities
      expect(wall, isA<CollisionCallbacks>());
      
      // Verify hitbox is properly configured for collision detection
      final hitbox = wall.children.whereType<RectangleHitbox>().first;
      expect(hitbox.size, equals(wall.size));
    });

    testWithFlameGame('can be positioned anywhere', (game) async {
      final positions = [
        Vector2(0, 0),
        Vector2(-100, -100),
        Vector2(500, 300),
        Vector2(1000, 1000),
      ];
      
      final walls = <Wall>[];
      
      for (final pos in positions) {
        final wall = Wall(position: pos, size: Vector2(50, 50));
        walls.add(wall);
        await game.ensureAdd(wall);
      }
      
      for (int i = 0; i < walls.length; i++) {
        expect(walls[i].position, equals(positions[i]));
      }
    });

    testWithFlameGame('supports various sizes', (game) async {
      final sizes = [
        Vector2(10, 10),    // Small square
        Vector2(1, 1000),   // Thin vertical
        Vector2(1000, 1),   // Thin horizontal
        Vector2(200, 150),  // Rectangle
      ];
      
      final walls = <Wall>[];
      
      for (final size in sizes) {
        final wall = Wall(position: Vector2.zero(), size: size);
        walls.add(wall);
        await game.ensureAdd(wall);
      }
      
      for (int i = 0; i < walls.length; i++) {
        expect(walls[i].size, equals(sizes[i]));
        
        // Verify hitbox matches wall size
        final hitbox = walls[i].children.whereType<RectangleHitbox>().first;
        expect(hitbox.size, equals(sizes[i]));
      }
    });
  });

  group('Wall Rendering', () {
    testWithFlameGame('does not render visibly by default', (game) async {
      final wall = Wall(
        position: Vector2(100, 100),
        size: Vector2(50, 50),
      );
      
      await game.ensureAdd(wall);

      // Walls should be invisible in normal gameplay (no visual rendering)
      // The render method should not draw anything visible
      // This is tested implicitly - walls only provide collision, not visuals
      expect(wall.children.whereType<SpriteComponent>().isEmpty, isTrue);
      
      // Walls only have collision hitboxes, no visual components
      final hitboxes = wall.children.whereType<RectangleHitbox>();
      expect(hitboxes.isNotEmpty, isTrue); // Should have collision
      
      // No visual rendering components
      final sprites = wall.children.whereType<SpriteComponent>();
      expect(sprites.isEmpty, isTrue);
    });
  });
}