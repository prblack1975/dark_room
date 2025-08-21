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

## Key Configuration

- **Dart SDK**: ^3.8.1
- **Linting**: Uses flutter_lints package for code quality
- **Package name**: com.haggoth.dark_room (Android/iOS)