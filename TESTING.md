# Local Testing Guide

## Prerequisites

Run this first to ensure everything is properly configured:
```bash
flutter doctor
flutter pub get
```

## Running the App Locally

### Quick Start (Auto-select device)
```bash
flutter run
```
This will show available devices and let you choose.

### Platform-Specific Commands

#### iOS Simulator
```bash
flutter run -d ios
```
Or launch Simulator first, then run:
```bash
open -a Simulator
flutter run
```

#### Android Emulator/Device
```bash
flutter run -d android
```

#### Web Browser
```bash
flutter run -d chrome
# or for web server mode:
flutter run -d web-server
```

#### macOS Desktop
```bash
flutter run -d macos
```

### Development Controls

While the app is running:
- **Hot Reload**: Press `r` to reload changes instantly
- **Hot Restart**: Press `R` to restart the app completely
- **Quit**: Press `q` to quit the app

### Check Available Devices
```bash
flutter devices
```

## Building for Release

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release --no-codesign
```

### Web
```bash
flutter build web --release
```

### macOS
```bash
flutter build macos --release
```

### Windows (Windows only)
```bash
flutter build windows --release
```

### Linux (Linux only)
```bash
flutter build linux --release
```

## Testing & Analysis

```bash
flutter test                    # Run all tests
flutter analyze                 # Static analysis
flutter pub outdated           # Check for dependency updates
```

## Troubleshooting

If you encounter issues:
1. Run `flutter clean` to clear build cache
2. Run `flutter pub get` to reinstall dependencies
3. Run `flutter doctor` to check environment setup