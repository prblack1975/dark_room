import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:dark_room/game/audio/audio_manager.dart';
import 'package:dark_room/game/audio/asset_audio_player.dart';
import 'package:dark_room/game/dark_room_game.dart';
import 'package:dark_room/game/levels/level.dart';

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

/// Universal test setup class for comprehensive testing environment
class UniversalTestSetup {
  static bool _isSetup = false;
  
  /// Set up complete testing environment with all necessary mocks
  static void setupCompleteTestEnvironment() {
    if (_isSetup) return;
    
    // Ensure Flutter bindings are initialized
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Setup audio mocking
    TestAudioSetup.setupTestEnvironment();
    
    // Setup comprehensive plugin mocks
    _setupAllPluginMocks();
    
    _isSetup = true;
    print('🧪 UNIVERSAL TEST: Complete testing environment initialized');
  }
  
  /// Setup all Flutter plugin mocks to prevent exceptions
  static void _setupAllPluginMocks() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    
    // Shared preferences mock
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAll':
            return <String, dynamic>{};
          case 'setString':
          case 'setBool':
          case 'setInt':
          case 'setDouble':
            return true;
          case 'getString':
            return null;
          case 'getBool':
            return false;
          case 'getInt':
            return 0;
          case 'getDouble':
            return 0.0;
          case 'remove':
            return true;
          case 'clear':
            return true;
          default:
            return null;
        }
      },
    );
    
    // Path provider mock
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getTemporaryDirectory':
            return '/tmp';
          case 'getApplicationSupportDirectory':
            return '/tmp/app_support';
          case 'getApplicationDocumentsDirectory':
            return '/tmp/documents';
          default:
            return '/tmp';
        }
      },
    );
    
    // Platform channel mock (for Flutter services)
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter/platform'),
      (MethodCall methodCall) async => null,
    );
    
    print('🧪 UNIVERSAL TEST: All plugin mocks configured');
  }
  
  /// Reset all mocks and clean up
  static void resetAllMocks() {
    TestAudioSetup.resetMocks();
    _isSetup = false;
    print('🧪 UNIVERSAL TEST: All mocks reset');
  }
}

/// Test game factory for creating isolated test games
class TestGameFactory {
  /// Create a game with isolated testing setup
  static DarkRoomGame createIsolatedGame({Vector2? playerSpawn}) {
    final game = DarkRoomGame();
    if (playerSpawn != null) {
      game.enableTestMode(playerSpawn: playerSpawn);
    } else {
      game.enableTestMode();
    }
    return game;
  }
  
  /// Create a game pre-loaded with a specific level for testing
  static DarkRoomGame createWithLevel(Level level, {Vector2? playerSpawn}) {
    final game = DarkRoomGame();
    game.enableTestMode(playerSpawn: playerSpawn);
    // Level will be set after game initialization
    return game;
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