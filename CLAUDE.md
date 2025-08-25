# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flame game application built with Flutter called "dark_room". Flame is a game engine built on top of Flutter for creating 2D games. The project targets iOS, Android, Linux, macOS, Windows, and Web platforms.

## Development Commands

### Running the Application
- `flutter run` - Run the app on connected device or emulator
- `flutter run -d chrome` - Run in Chrome browser
- `flutter run -d macos` - Run on macOS
- `flutter run -d ios` - Run on iOS simulator

### Building
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build web` - Build for web deployment
- `flutter build macos` - Build macOS app
- `flutter build windows` - Build Windows app
- `flutter build linux` - Build Linux app

### Testing & Analysis
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run specific test file
- `flutter analyze` - Run static analysis and linting

### Dependencies
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies
- `flutter pub outdated` - Check for outdated dependencies

### Development Tools
- `flutter doctor` - Check Flutter environment setup
- `flutter clean` - Clean build artifacts

## Code Architecture

The project follows standard Flutter application structure with Flame game engine integration:

- **lib/main.dart**: Entry point for the Flame game application
- **Game Components**: Flame games typically organize game logic, components, sprites, and systems in lib/
- **Platform-specific code**: Located in android/, ios/, linux/, macos/, windows/, and web/ directories
- **Tests**: Located in test/ directory
- **Configuration**: 
  - pubspec.yaml defines dependencies including Flame and Flutter configuration
  - analysis_options.yaml configures Dart analyzer with flutter_lints package

## Flame Game Development Notes

- Flame uses a component-based architecture with GameWidget as the root widget
- Game logic is typically implemented by extending FlameGame class
- Components (sprites, text, shapes) extend Component class
- Input handling through gesture detectors and keyboard events
- Game loop handles update and render cycles automatically

## Game Interaction Rules

**IMPORTANT**: The Dark Room game has specific interaction patterns that must be followed:

- **Always-Playing Sound Sources**: Sound sources continuously play their audio loops at their fixed positions - they never stop or start based on player actions. Players navigate by hearing these persistent environmental sounds.
- **Proximity-Based Volume**: All sound sources get louder as the player approaches and quieter as they move away. Volume changes smoothly based on 3D distance calculations.
- **Wall and Room Attenuation**: Walls and separate rooms significantly reduce sound volume and add muffling effects (low-pass filtering). This creates realistic audio occlusion.
- **Variable Sound Ranges**: Each sound source has its own effective radius:
  - Small objects: ~100 units (music boxes, clocks, small electronics)
  - Medium objects: ~200 units (fans, computers, appliances)
  - Large objects: ~400+ units (generators, HVAC, major water features)
- **Automatic Item Pickup**: Items (keys, etc.) are picked up automatically when the player gets close enough - no manual interaction required.
- **Automatic Door Unlocking**: Doors automatically unlock when the player approaches with the required key in inventory.
- **NO Manual Activation**: Never implement manual interaction systems (like pressing buttons to activate sounds). All audio interaction is automatic and proximity-based.

## Testing Guidelines

**CRITICAL**: To prevent the test/implementation cycle that breaks game functionality:

### Audio Testing Approach
- **NEVER disable audio calls in the implementation** - this breaks actual gameplay
- **USE proper mocking instead** - Audio systems have built-in test detection
- **AudioManager and AssetAudioPlayer** automatically use test mode when `TestAudioSetup.setupTestEnvironment()` is called
- **Test the game logic** (distance calculations, pickup radius, inventory updates) **NOT audio playback**

### Test Setup Pattern
```dart
import '../../helpers/test_setup.dart';

void main() {
  setUpAll(() {
    TestAudioSetup.setupTestEnvironment(); // Enables test mode for all audio
  });
  
  tearDownAll(() {
    TestAudioSetup.resetMocks();
  });
}
```

### What to Test vs Mock
- **✅ TEST**: Volume calculations, distance logic, pickup radius, inventory state changes, game object interactions
- **🚫 MOCK**: AudioPlayer creation, actual audio playback, file loading, platform-specific audio calls
- **✅ VERIFY**: Game logic works correctly, state changes properly, systems integrate correctly

### Running Tests
- `flutter test` - All tests with proper audio mocking
- `flutter analyze` - Static analysis and linting
- **Manual verification**: Always run the actual game to verify audio and pickup functionality

### Debugging Test Issues
- If tests fail with `MissingPluginException`: Audio mocking not set up correctly
- If pickup doesn't work in game but tests pass: Implementation was modified to "fix" tests
- If audio doesn't work in game: Check that test mode detection isn't enabled in production

**Remember**: The game functionality (audio, pickup, proximity) should always work perfectly. Tests should validate logic without interfering with actual gameplay.

## Key Configuration

- **Dart SDK**: ^3.8.1
- **Linting**: Uses flutter_lints package for code quality
- **Package name**: com.haggoth.dark_room (Android/iOS)