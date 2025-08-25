import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dark_room/game/dark_room_game.dart';
import 'package:dark_room/game/components/player.dart';
import 'package:dark_room/game/levels/menu_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Integration Tests - Basic Game Flow', () {
    testWithGame<DarkRoomGame>(
      'game initializes and player can be moved',
      () => DarkRoomGame(),
      (game) async {
        final player = game.player;
        final initialPosition = player.position.clone();
        
        // Apply movement input
        player.updateMovement({LogicalKeyboardKey.keyD});
        
        // Update for a few frames
        for (int i = 0; i < 5; i++) {
          player.update(1/60);
        }
        
        // Player should have moved
        expect(player.position.x, greaterThan(initialPosition.x));
        
        // Stop movement
        player.updateMovement({});
        expect(player.velocity, equals(Vector2.zero()));
      },
    );

    testWithGame<DarkRoomGame>(
      'debug mode toggle works',
      () => DarkRoomGame(),
      (game) async {
        expect(game.debugMode, isFalse);
        
        game.toggleDebugMode();
        expect(game.debugMode, isTrue);
        
        game.toggleDebugMode();
        expect(game.debugMode, isFalse);
      },
    );

    testWithGame<DarkRoomGame>(
      'game starts with menu level',
      () => DarkRoomGame(),
      (game) async {
        expect(game.currentLevel, isA<MenuLevel>());
        expect(game.player, isNotNull);
        expect(game.player.position, equals(Vector2(400, 300)));
      },
    );

    testWithGame<DarkRoomGame>(
      'pause functionality works',
      () => DarkRoomGame(),
      (game) async {
        expect(game.isGamePaused, isFalse);
        
        game.togglePause();
        expect(game.isGamePaused, isTrue);
        
        game.togglePause();
        expect(game.isGamePaused, isFalse);
      },
    );
  });
}