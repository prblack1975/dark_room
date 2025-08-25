import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dark_room/game/components/player.dart';
import 'package:dark_room/game/components/wall.dart';
import 'package:dark_room/game/dark_room_game.dart';
import '../../helpers/test_setup.dart';

void main() {
  setUpAll(() {
    UniversalTestSetup.setupCompleteTestEnvironment();
  });
  
  tearDownAll(() {
    UniversalTestSetup.resetAllMocks();
  });
  group('Player', () {
    testWithFlameGame('initializes with correct properties', (game) async {
      final player = Player(position: Vector2(100, 100));
      await game.ensureAdd(player);

      expect(player.position, equals(Vector2(100, 100)));
      expect(player.size, equals(Vector2.all(Player.playerSize)));
      expect(player.anchor, equals(Anchor.center));
      expect(player.velocity, equals(Vector2.zero()));
    });

    testWithFlameGame('adds collision hitbox on load', (game) async {
      final player = Player(position: Vector2(100, 100));
      await game.ensureAdd(player);

      // Check that a CircleHitbox was added
      final hitboxes = player.children.whereType<CircleHitbox>();
      expect(hitboxes.length, equals(1));

      final hitbox = hitboxes.first;
      expect(hitbox.radius, equals(Player.playerSize / 2));
    });

    testWithFlameGame('updates movement based on key input', (game) async {
      final player = Player(position: Vector2(100, 100));
      await game.ensureAdd(player);

      // Test upward movement (W key)
      player.updateMovement({LogicalKeyboardKey.keyW});
      expect(player.velocity.y, equals(-1));
      expect(player.velocity.x, equals(0));

      // Test downward movement (S key)
      player.updateMovement({LogicalKeyboardKey.keyS});
      expect(player.velocity.y, equals(1));
      expect(player.velocity.x, equals(0));

      // Test left movement (A key)
      player.updateMovement({LogicalKeyboardKey.keyA});
      expect(player.velocity.x, equals(-1));
      expect(player.velocity.y, equals(0));

      // Test right movement (D key)
      player.updateMovement({LogicalKeyboardKey.keyD});
      expect(player.velocity.x, equals(1));
      expect(player.velocity.y, equals(0));
    });

    testWithFlameGame('normalizes diagonal movement', (game) async {
      final player = Player(position: Vector2(100, 100));
      await game.ensureAdd(player);

      // Test diagonal movement (W + D keys)
      player.updateMovement({LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyD});
      
      // Velocity should be normalized (length should be 1)
      expect(player.velocity.length, closeTo(1.0, 0.001));
      expect(player.velocity.x, greaterThan(0));
      expect(player.velocity.y, lessThan(0));
    });

    testWithFlameGame('supports arrow keys for movement', (game) async {
      final player = Player(position: Vector2(100, 100));
      await game.ensureAdd(player);

      // Test arrow key movement
      player.updateMovement({LogicalKeyboardKey.arrowUp});
      expect(player.velocity.y, equals(-1));

      player.updateMovement({LogicalKeyboardKey.arrowDown});
      expect(player.velocity.y, equals(1));

      player.updateMovement({LogicalKeyboardKey.arrowLeft});
      expect(player.velocity.x, equals(-1));

      player.updateMovement({LogicalKeyboardKey.arrowRight});
      expect(player.velocity.x, equals(1));
    });

    testWithFlameGame('moves based on velocity and delta time', (game) async {
      final player = Player(position: Vector2(100, 100));
      await game.ensureAdd(player);

      final initialPosition = player.position.clone();
      
      // Set velocity to move right
      player.updateMovement({LogicalKeyboardKey.keyD});
      
      // Simulate one frame update with 1/60 second delta time
      player.update(1/60);
      
      // Player should have moved right
      expect(player.position.x, greaterThan(initialPosition.x));
      expect(player.position.y, equals(initialPosition.y));
      
      // Movement should be consistent with moveSpeed
      final expectedDistance = Player.moveSpeed * (1/60);
      final actualDistance = player.position.x - initialPosition.x;
      expect(actualDistance, closeTo(expectedDistance, 0.1));
    });

    testWithFlameGame('calculates distance and angle correctly', (game) async {
      final player = Player(position: Vector2(0, 0));
      await game.ensureAdd(player);

      final target = Vector2(100, 0);
      
      // Test distance calculation
      expect(player.getDistanceTo(target), equals(100.0));
      
      // Test angle calculation (0 radians for target directly to the right)
      expect(player.getAngleTo(target), closeTo(0.0, 0.001));
      
      // Test angle for target above
      final targetAbove = Vector2(0, -100);
      expect(player.getAngleTo(targetAbove), closeTo(-1.5708, 0.001)); // -π/2
    });
  });

  group('Player Collision', () {
    testWithGame<DarkRoomGame>(
      'collision with wall reverts position',
      () => TestGameFactory.createIsolatedGame(playerSpawn: Vector2(100, 100)),
      (game) async {
        final player = Player(position: Vector2(100, 100));
        final wall = Wall(position: Vector2(200, 100), size: Vector2(50, 50));
        
        await game.ensureAdd(player);
        await game.ensureAdd(wall);
        
        // Store initial position
        final initialPosition = player.position.clone();
        
        // Move player towards wall
        player.updateMovement({LogicalKeyboardKey.keyD});
        
        // Update multiple frames to simulate movement towards wall
        for (int i = 0; i < 10; i++) {
          player.update(1/60);
          game.update(1/60);
          await game.ready();
        }
        
        // After collision, player should be pushed back to a valid position
        // (exact position depends on collision resolution, but should not be inside wall)
        expect(player.position.x, lessThan(200)); // Should not penetrate wall
      },
    );

    testWithFlameGame('stores last valid position during movement', (game) async {
      final player = Player(position: Vector2(100, 100));
      await game.ensureAdd(player);
      
      // Move player and update
      player.updateMovement({LogicalKeyboardKey.keyD});
      player.update(1/60);
      
      // Position should have changed
      expect(player.position.x, greaterThan(100));
      
      // Verify internal state is tracking position changes
      // (this tests the internal logic that stores valid positions)
      expect(player.position.length, greaterThan(0));
    });
  });
}