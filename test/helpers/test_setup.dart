import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:dark_room/game/audio/audio_manager.dart';
import 'package:dark_room/game/audio/asset_audio_player.dart';

// Import the generated mocks
import 'test_setup.mocks.dart';

// Export mock classes for easy importing in tests
export 'test_setup.mocks.dart' show MockAudioManager, MockAudioPlayer, MockAssetAudioPlayer;

// Generate mock classes
@GenerateMocks([
  AudioPlayer,
  AudioManager,
  AssetAudioPlayer,
])
void main() {}

/// Test setup utility that provides mocked audio components
class TestAudioSetup {
  static MockAudioManager? _mockAudioManager;
  static MockAssetAudioPlayer? _mockAssetAudioPlayer;
  
  /// Get or create a mock AudioManager instance
  static MockAudioManager getMockAudioManager() {
    _mockAudioManager ??= MockAudioManager();
    
    // Set up default behaviors for the mock
    when(_mockAudioManager!.startContinuousSound(any)).thenAnswer((_) async => {});
    when(_mockAudioManager!.updateContinuousSoundVolume(any, any, any, maxDistance: anyNamed('maxDistance')))
        .thenAnswer((_) async => {});
    when(_mockAudioManager!.setSoundVolume(any, any)).thenAnswer((_) async => {});
    when(_mockAudioManager!.setSoundBalance(any, any)).thenAnswer((_) async => {});
    when(_mockAudioManager!.playSound(any, volume: anyNamed('volume'))).thenAnswer((_) async => {});
    when(_mockAudioManager!.stopSound(any)).thenAnswer((_) async => {});
    
    // Mock the calculate3DAudio method with realistic behavior
    when(_mockAudioManager!.calculate3DAudio(any, any, maxDistance: anyNamed('maxDistance')))
        .thenAnswer((invocation) {
      // Extract arguments
      final playerPos = invocation.positionalArguments[0] as Vector2;
      final soundPos = invocation.positionalArguments[1] as Vector2;
      final maxDistance = invocation.namedArguments[#maxDistance] as double? ?? 200.0;
      
      // Calculate realistic volume based on distance
      final distance = playerPos.distanceTo(soundPos);
      double volume = 1.0;
      if (distance > maxDistance) {
        volume = 0.0;
      } else if (distance > 0) {
        volume = (maxDistance - distance) / maxDistance;
        volume = volume.clamp(0.0, 1.0);
      }
      
      // Calculate balance (simplified)
      double balance = 0.0;
      if (distance > 0) {
        final direction = soundPos - playerPos;
        balance = (direction.x / maxDistance).clamp(-1.0, 1.0);
      }
      
      return AudioSpatialData(
        volume: volume,
        balance: balance,
        distance: distance,
      );
    });
    
    return _mockAudioManager!;
  }
  
  /// Get or create a mock AssetAudioPlayer instance
  static MockAssetAudioPlayer getMockAssetAudioPlayer() {
    _mockAssetAudioPlayer ??= MockAssetAudioPlayer();
    
    // Set up default behaviors for the mock
    when(_mockAssetAudioPlayer!.startContinuousSound(any, any)).thenAnswer((_) async => {});
    when(_mockAssetAudioPlayer!.setContinuousSoundVolume(any, any)).thenAnswer((_) async => {});
    when(_mockAssetAudioPlayer!.stopContinuousSound(any)).thenAnswer((_) async => {});
    when(_mockAssetAudioPlayer!.dispose()).thenAnswer((_) async => {});
    
    return _mockAssetAudioPlayer!;
  }
  
  /// Reset all mocks for clean test state
  static void resetMocks() {
    _mockAudioManager = null;
    _mockAssetAudioPlayer = null;
    // Reset the test instance in AudioManager and AssetAudioPlayer
    AudioManager.setTestInstance(null);
    AssetAudioPlayer.setTestInstance(null);
  }
  
  /// Set up Flutter test binding and audio mocks
  static void setupTestEnvironment() {
    TestWidgetsFlutterBinding.ensureInitialized();
    resetMocks();
    
    // Enable test mode in AudioManager to prevent real audio loading
    AudioManager.setTestInstance(getMockAudioManager());
    
    // Also enable test mode in AssetAudioPlayer
    AssetAudioPlayer.setTestInstance(getMockAssetAudioPlayer());
  }
}

/// Extension to provide easy access to mock audio manager in tests
extension TestAudioExtension on AudioManager {
  static MockAudioManager? _testMockInstance;
  
  /// Use this in tests to get a mocked AudioManager instead of the real one
  static AudioManager getTestInstance() {
    _testMockInstance ??= TestAudioSetup.getMockAudioManager();
    return _testMockInstance!;
  }
  
  /// Reset the test instance (call in tearDown)
  static void resetTestInstance() {
    _testMockInstance = null;
  }
}