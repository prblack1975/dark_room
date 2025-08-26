import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:dark_room/game/dark_room_game.dart';
import 'package:dark_room/game/audio/audio_manager.dart';
import 'test_setup.dart';

/// A test-specific version of DarkRoomGame that uses mocked audio components
class TestDarkRoomGame extends DarkRoomGame {
  late MockAudioManager mockAudioManager;
  
  @override
  Future<void> onLoad() async {
    // Set up test environment
    TestAudioSetup.setupTestEnvironment();
    mockAudioManager = TestAudioSetup.getMockAudioManager();
    
    // Continue with normal game initialization
    await super.onLoad();
  }
  
  /// Override the audio manager getter to return our mock
  @override
  AudioManager get audioManager => mockAudioManager;
}

/// Helper function to create and run tests with a properly mocked game
void testWithMockedGame<T extends DarkRoomGame>(
  String testName,
  T Function() gameBuilder,
  Future<void> Function(T game) testFunction, {
  int? skip,
  String? skipReason,
  dynamic tags,
}) {
  testWidgets(testName, (tester) async {
    final game = gameBuilder();
    
    // Initialize the game
    await tester.pumpWidget(GameWidget<T>.controlled(gameFactory: () => game));
    await tester.pump();
    
    // Wait for game to load
    await game.ready();
    
    // Run the test
    await testFunction(game);
  }, skip: skip != null ? skip != 0 : null, tags: tags);
}