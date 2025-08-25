# Dark Room Game

An immersive audio-based adventure game built with Flutter and Flame. Navigate through dark environments using spatial audio cues to find objects and solve puzzles.

## 🎮 About Dark Room

Dark Room is a unique gaming experience designed around spatial audio navigation. Players explore environments in complete darkness, relying entirely on 3D audio positioning to:

- Navigate through rooms and corridors
- Locate interactive objects and items
- Solve puzzles using audio cues
- Progress through increasingly complex levels

### Key Features
- **Spatial Audio Navigation**: 3D audio positioning for immersive exploration
- **Automatic Item Detection**: Items are picked up when you get close enough
- **Progressive Difficulty**: Multiple levels with increasing complexity
- **Cross-Platform**: Available on Web, Android, iOS, Windows, macOS, and Linux
- **Accessibility First**: Designed specifically for audio-based gameplay

## 🚀 Quick Start

### Playing the Game

**Web Version**: Play directly in your browser at the GitHub Pages deployment

**Mobile & Desktop**: Download builds from the latest GitHub release

### Building from Source

This project uses a comprehensive local build system:

```bash
# Check your build environment
./scripts/check-build-env.sh

# Build all platforms
./scripts/build-all.sh --parallel

# Deploy to web and create release
./scripts/deploy.sh
```

📖 **For detailed build instructions, see [BUILD_GUIDE.md](BUILD_GUIDE.md)**

## 🛠️ Development

### Prerequisites
- Flutter SDK (3.35.1+)
- Platform-specific development tools
- Git and GitHub CLI (for deployment)

### Running Locally
```bash
flutter run -d chrome    # Web version
flutter run -d macos     # Native desktop
flutter run               # Connected device
```

### Project Structure
- `lib/` - Game source code (Flame game engine)
- `assets/audio/` - Spatial audio files
- `scripts/` - Build and deployment automation
- `test/` - Game logic and audio system tests

## 📱 Platform Support

- **🌐 Web**: Browser-based play (Chrome, Firefox, Safari, Edge)
- **📱 Mobile**: Android APK, iOS (requires signing)
- **🖥️ Desktop**: Windows, macOS, Linux native apps

## 🔊 Audio Requirements

- **Headphones recommended** for optimal spatial audio experience
- Modern browser with Web Audio API support (for web version)
- Audio permissions enabled

## 📄 Documentation

- **[BUILD_GUIDE.md](BUILD_GUIDE.md)** - Complete build and deployment guide
- **[CLAUDE.md](CLAUDE.md)** - Development environment setup and commands

## 🤝 Contributing

1. Check the build environment: `./scripts/check-build-env.sh`
2. Run tests: `flutter test`
3. Build and verify: `./scripts/build-all.sh --platforms=web`

## 📜 License

This project is available under the MIT License.
