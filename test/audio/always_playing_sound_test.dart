import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:dark_room/game/audio/audio_manager.dart';
import 'package:dark_room/game/components/game_object.dart';
import 'package:dark_room/game/levels/tutorial_level.dart';

void main() {
  group('Always-Playing Sound System Tests', () {
    late AudioManager audioManager;
    
    setUp(() {
      audioManager = AudioManager();
    });
    
    tearDown(() {
      audioManager.dispose();
    });
    
    test('AudioManager can start continuous sound', () async {
      // This test verifies the AudioManager can handle continuous sounds
      // Note: In a real environment, this would use actual audio files
      
      expect(() => audioManager.startContinuousSound('test_sound'), returnsNormally);
    });
    
    test('AudioManager can update continuous sound volume', () async {
      const soundName = 'test_sound';
      final playerPos = Vector2(100, 100);
      final soundPos = Vector2(150, 150);
      
      // This test verifies volume updates work for continuous sounds
      expect(() => audioManager.updateContinuousSoundVolume(
        soundName, 
        playerPos, 
        soundPos, 
        maxDistance: 200,
      ), returnsNormally);
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
      
      // Test updateSpatialAudio doesn't throw
      final playerPosition = Vector2(100, 100);
      expect(() => soundSource.updateSpatialAudio(playerPosition), returnsNormally);
    });
    
    test('Level can initialize multiple sound sources', () async {
      final level = TutorialLevel();
      
      // This would test the initialization of sound sources in the level
      // Note: In a real test environment, we'd mock the audio loading
      expect(() => level.buildLevel(), returnsNormally);
    });
    
    test('Audio volume calculation works correctly', () {
      const maxDistance = 200.0;
      final playerPos = Vector2(100, 100);
      
      // Test volume at different distances
      var soundPos = Vector2(100, 100); // Same position
      var spatialData = audioManager.calculate3DAudio(playerPos, soundPos, maxDistance: maxDistance);
      expect(spatialData.volume, 1.0); // Maximum volume at same position
      
      soundPos = Vector2(200, 100); // 100 units away
      spatialData = audioManager.calculate3DAudio(playerPos, soundPos, maxDistance: maxDistance);
      expect(spatialData.volume, 0.5); // Half volume at half max distance
      
      soundPos = Vector2(300, 100); // 200 units away (max distance)
      spatialData = audioManager.calculate3DAudio(playerPos, soundPos, maxDistance: maxDistance);
      expect(spatialData.volume, 0.0); // No volume at max distance
      
      soundPos = Vector2(400, 100); // Beyond max distance
      spatialData = audioManager.calculate3DAudio(playerPos, soundPos, maxDistance: maxDistance);
      expect(spatialData.volume, 0.0); // No volume beyond max distance
    });
  });
}