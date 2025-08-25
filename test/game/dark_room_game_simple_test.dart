import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dark_room/game/dark_room_game.dart';
import 'package:dark_room/game/components/player.dart';
import 'package:dark_room/game/levels/level.dart';
import 'package:dark_room/game/levels/menu_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('DarkRoomGame (Simple Tests)', () {
    testWithGame<DarkRoomGame>(
      'initializes with correct basic properties',
      () => DarkRoomGame(),
      (game) async {
        expect(game.debugMode, isFalse);
        expect(game.isGamePaused, isFalse);
        // Wait for game to fully load before checking player
        await game.ready();
        expect(game.player, isNotNull);
        expect(game.currentLevel, isA<MenuLevel>());
      },
    );

    testWithGame<DarkRoomGame>(
      'has correct camera configuration',
      () => DarkRoomGame(),
      (game) async {
        expect(game.camera.viewfinder.visibleGameSize, equals(Vector2(800, 600)));
      },
    );

    testWithGame<DarkRoomGame>(
      'player is positioned correctly initially',
      () => DarkRoomGame(),
      (game) async {
        await game.ready();
        final player = game.player!;
        expect(player.position, equals(Vector2(400, 300)));
      },
    );

    testWithGame<DarkRoomGame>(
      'contains exactly one level at startup',
      () => DarkRoomGame(),
      (game) async {
        expect(game.children.whereType<Level>().length, equals(1));
        expect(game.currentLevel, isA<MenuLevel>());
      },
    );
  });

  group('DarkRoomGame Debug Mode (Simple)', () {
    testWithGame<DarkRoomGame>(
      'debug mode can be toggled',
      () => DarkRoomGame(),
      (game) async {
        // Initially debug mode should be off
        expect(game.debugMode, isFalse);
        
        // Toggle debug mode
        game.toggleDebugMode();
        expect(game.debugMode, isTrue);
        
        // Toggle again
        game.toggleDebugMode();
        expect(game.debugMode, isFalse);
      },
    );
  });

  group('DarkRoomGame State Management (Simple)', () {
    testWithGame<DarkRoomGame>(
      'pause state can be toggled',
      () => DarkRoomGame(),
      (game) async {
        expect(game.isGamePaused, isFalse);
        
        game.togglePause();
        expect(game.isGamePaused, isTrue);
        
        game.togglePause();
        expect(game.isGamePaused, isFalse);
      },
    );

    testWithGame<DarkRoomGame>(
      'complete level returns to menu',
      () => DarkRoomGame(),
      (game) async {
        // Should start on menu
        expect(game.currentLevel, isA<MenuLevel>());
        
        // Complete level should keep us on menu
        game.completeLevel();
        await game.ready();
        
        expect(game.currentLevel, isA<MenuLevel>());
      },
    );
  });

  group('DarkRoomGame Player Integration (Simple)', () {
    testWithGame<DarkRoomGame>(
      'player exists and is accessible',
      () => DarkRoomGame(),
      (game) async {
        expect(game.player, isNotNull);
        expect(game.player, isA<Player>());
      },
    );

    testWithGame<DarkRoomGame>(
      'player is added to current level',
      () => DarkRoomGame(),
      (game) async {
        await game.ready();
        expect(game.currentLevel!.children.contains(game.player), isTrue);
      },
    );
  });
}