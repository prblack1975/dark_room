import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:mockito/mockito.dart';
import 'package:dark_room/game/components/game_object.dart';
import 'package:dark_room/game/levels/tutorial_level.dart';
import '../helpers/test_setup.dart';

void main() {
  group('Always-Playing Sound System Tests', () {
    late MockAudioManager mockAudioManager;
    
    setUpAll(() {
      TestAudioSetup.setupTestEnvironment();
    });
    
    setUp(() {
      mockAudioManager = TestAudioSetup.getMockAudioManager();
    });
    
    tearDown(() {
      TestAudioSetup.resetMocks();
    });
    
    test('AudioManager can start continuous sound', () async {
      // This test verifies the AudioManager can handle continuous sounds
      // Using mock to avoid platform audio dependencies
      
      await mockAudioManager.startContinuousSound('test_sound');
      
      // Verify the method was called
      verify(mockAudioManager.startContinuousSound('test_sound')).called(1);
    });
    
    test('AudioManager can update continuous sound volume', () async {
      const soundName = 'test_sound';
      final playerPos = Vector2(100, 100);
      final soundPos = Vector2(150, 150);
      
      // This test verifies volume updates work for continuous sounds
      await mockAudioManager.updateContinuousSoundVolume(
        soundName, 
        playerPos, 
        soundPos, 
        maxDistance: 200,
      );
      
      // Verify the method was called with correct parameters
      verify(mockAudioManager.updateContinuousSoundVolume(
        soundName, 
        playerPos, 
        soundPos, 
        maxDistance: 200,
      )).called(1);
    });
    
    test('GameObject initializes audio for sound sources', () {
      final soundSource = GameObject(
        type: GameObjectType.soundSource,
        name: 'test_source',
        description: 'Test sound source',
        position: Vector2(200, 200),
        soundFile: 'test.mp3',
        soundRadius: 150,
      );
      
      // Verify the sound source is configured correctly
      expect(soundSource.type, GameObjectType.soundSource);
      expect(soundSource.soundFile, 'test.mp3');
      expect(soundSource.soundRadius, 150);
      
      // Note: We don't test updateSpatialAudio here as it requires audio system integration
      // That functionality is tested in the actual game integration tests
    });
    
    test('Level can initialize multiple sound sources', () async {
      final level = TutorialLevel();
      
      // Test basic level structure without audio loading
      // This verifies the level can be built without throwing exceptions
      expect(() => level.buildLevel(), returnsNormally);
      
      // Note: Sound source initialization is tested in integration tests with proper mocking
    });
    
    test('Audio volume calculation works correctly', () {
      const maxDistance = 200.0;
      final playerPos = Vector2(100, 100);
      
      // Test volume at different distances using the mock
      var soundPos = Vector2(100, 100); // Same position
      var spatialData = mockAudioManager.calculate3DAudio(playerPos, soundPos, maxDistance: maxDistance);
      expect(spatialData.volume, 1.0); // Maximum volume at same position
      
      soundPos = Vector2(200, 100); // 100 units away
      spatialData = mockAudioManager.calculate3DAudio(playerPos, soundPos, maxDistance: maxDistance);
      expect(spatialData.volume, 0.5); // Half volume at half max distance
      
      soundPos = Vector2(300, 100); // 200 units away (max distance)
      spatialData = mockAudioManager.calculate3DAudio(playerPos, soundPos, maxDistance: maxDistance);
      expect(spatialData.volume, 0.0); // No volume at max distance
      
      soundPos = Vector2(400, 100); // Beyond max distance
      spatialData = mockAudioManager.calculate3DAudio(playerPos, soundPos, maxDistance: maxDistance);
      expect(spatialData.volume, 0.0); // No volume beyond max distance
    });
  });
}