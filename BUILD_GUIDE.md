# Dark Room Game - Build System Guide

This guide provides comprehensive instructions for building and deploying the Dark Room game across all supported platforms using the local build system.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Platform-Specific Builds](#platform-specific-builds)
- [Advanced Usage](#advanced-usage)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## 🎯 Overview

The Dark Room game uses a local build system that replaces GitHub Actions with:
- **Zero cloud costs** - All builds run on your machine
- **Faster builds** - No queuing, direct hardware access
- **Full control** - Customize every aspect of the build process
- **Multiple platforms** - Web, Android, iOS, Windows, macOS, Linux
- **Automated deployment** - GitHub Pages + GitHub Releases

## 🛠️ Prerequisites

### Required Software

1. **Flutter SDK** (3.35.1+)
   ```bash
   flutter doctor  # Verify installation
   ```

2. **Git** 
   ```bash
   git --version
   ```

3. **Platform-specific requirements:**
   - **Android**: Android SDK, Java 11+
   - **iOS**: Xcode (macOS only)
   - **Web**: Chrome/Chromium for testing
   - **Desktop**: Platform-specific compilers

### Environment Setup

Run the environment checker to verify all dependencies:

```bash
./scripts/check-build-env.sh
```

To automatically fix common issues:

```bash
./scripts/check-build-env.sh --fix
```

## 🚀 Quick Start

### 1. Check Your Environment
```bash
# Verify all build dependencies
./scripts/check-build-env.sh

# Check specific platforms only
./scripts/check-build-env.sh --platforms=web,android
```

### 2. Build All Platforms
```bash
# Build everything in parallel (fastest)
./scripts/build-all.sh --parallel

# Build sequentially (more stable)
./scripts/build-all.sh

# Debug builds for development
./scripts/build-all.sh --build-type=debug
```

### 3. Deploy
```bash
# Full deployment (web + GitHub release)
./scripts/deploy.sh

# Web deployment only
./scripts/deploy.sh --web-only

# Create draft release for testing
./scripts/deploy.sh --draft
```

## 🏗️ Platform-Specific Builds

### Android 📱

Build Android APK and AAB files:

```bash
# Release builds (both APK and AAB)
./scripts/build-android.sh

# Debug build
./scripts/build-android.sh debug

# APK only
./scripts/build-android.sh release apk

# AAB only (for Play Store)
./scripts/build-android.sh release aab
```

**Output Location:** `dist/android/`
- `dark_room-android-release.apk` - Sideload APK
- `dark_room-android-release.aab` - Google Play Store

**Installation:**
1. Enable "Install from unknown sources" on Android device
2. Transfer APK to device and install
3. For Play Store: Upload AAB to Google Play Console

### iOS 🍎

Build iOS app (requires macOS):

```bash
# Device build (unsigned)
./scripts/build-ios.sh

# Simulator build
./scripts/build-ios.sh release simulator

# Debug build
./scripts/build-ios.sh debug device
```

**Output Location:** `dist/ios/`
- `dark_room-ios-device-release.app.tar.gz` - Device build
- `dark_room-ios-simulator-release.app.tar.gz` - Simulator build

**Installation:**
1. Extract the archive
2. For device: Requires code signing with your Apple Developer certificate
3. For simulator: Drag to iOS Simulator

### Web 🌐

Build web version for browser play:

```bash
# Standard build
./scripts/build-web.sh

# Debug build
./scripts/build-web.sh debug

# Custom base href (for subdirectories)
./scripts/build-web.sh release --base-href=/dark-room/
```

**Output Location:** `dist/web/`
- Complete web application ready to deploy

**Testing Locally:**
```bash
cd dist/web
python -m http.server 8000
# Visit http://localhost:8000
```

**Deploy to GitHub Pages:**
```bash
./scripts/deploy-web.sh
```

### Windows 🪟

Build Windows executable:

```bash
# Windows build (can run on any OS with proper setup)
./scripts/build-desktop.sh windows

# All desktop platforms
./scripts/build-desktop.sh all
```

**Output Location:** `dist/desktop/windows/`
- `dark_room-windows-release.zip` - Windows executable package

**Installation:**
1. Extract ZIP file
2. Run `dark_room.exe`
3. Windows may show security warning (normal for unsigned executables)

### macOS 🍎

Build macOS application (requires macOS):

```bash
# macOS build
./scripts/build-desktop.sh macos

# Debug build
./scripts/build-desktop.sh macos debug
```

**Output Location:** `dist/desktop/macos/`
- `dark_room-macos-release.tar.gz` - macOS app bundle

**Installation:**
1. Extract archive
2. Move `dark_room.app` to Applications folder
3. First run: Right-click → Open (to bypass Gatekeeper)

### Linux 🐧

Build Linux executable:

```bash
# Linux build
./scripts/build-desktop.sh linux

# On non-Linux systems (may require Docker)
./scripts/build-desktop.sh linux
```

**Output Location:** `dist/desktop/linux/`
- `dark_room-linux-release.tar.gz` - Linux executable package

**Installation:**
1. Extract archive
2. Make executable: `chmod +x dark_room`
3. Run: `./dark_room`

## 🔧 Advanced Usage

### Version Management

```bash
# Show current version
./scripts/version-manager.sh current

# Bump version
./scripts/version-manager.sh bump patch    # 1.0.0 → 1.0.1
./scripts/version-manager.sh bump minor    # 1.0.1 → 1.1.0
./scripts/version-manager.sh bump major    # 1.1.0 → 2.0.0

# Set specific version
./scripts/version-manager.sh set 1.2.3

# Manage build numbers
./scripts/version-manager.sh build-number increment
./scripts/version-manager.sh build-number set 42
```

### Build Orchestration

```bash
# Build specific platforms only
./scripts/build-all.sh --platforms=web,android

# Parallel vs sequential builds
./scripts/build-all.sh --parallel        # Faster, uses more resources
./scripts/build-all.sh                   # Safer, uses less resources

# Clean build (removes all previous artifacts)
./scripts/build-all.sh --clean

# Skip tests (faster, but less safe)
./scripts/build-all.sh --skip-tests
```

### Artifact Management

```bash
# Organize build artifacts with consistent naming
./scripts/artifact-manager.sh organize

# Create deployment archives
./scripts/artifact-manager.sh archive --separate-platforms

# List all current artifacts
./scripts/artifact-manager.sh list

# Verify artifact integrity
./scripts/artifact-manager.sh verify

# Prepare for specific upload services
./scripts/artifact-manager.sh upload-prep github
./scripts/artifact-manager.sh upload-prep itch
./scripts/artifact-manager.sh upload-prep stores
```

### Changelog Generation

```bash
# Generate changelog for current version
./scripts/changelog-generator.sh generate

# Generate release notes for GitHub
./scripts/changelog-generator.sh release-notes

# Update existing changelog
./scripts/changelog-generator.sh update 1.2.3

# Show changelog for specific version
./scripts/changelog-generator.sh show 1.2.0
```

## 🚀 Deployment

### Full Deployment Pipeline

```bash
# Complete release workflow
./scripts/deploy.sh

# With custom options
./scripts/deploy.sh --version=1.2.3 --prerelease --draft
```

This will:
1. Validate environment
2. Increment version (for release builds)
3. Build all platforms
4. Deploy web version to GitHub Pages
5. Create GitHub release with all assets
6. Generate deployment report

### GitHub Pages Only

```bash
# Deploy web version only
./scripts/deploy-web.sh

# Force deployment (overwrites history)
./scripts/deploy-web.sh --force

# Custom base href
./scripts/deploy-web.sh --base-href=/my-game/
```

### GitHub Releases

```bash
# Install GitHub CLI first
brew install gh  # macOS
# or download from https://cli.github.com/

# Authenticate
gh auth login

# Create release (includes building)
./scripts/release-manager.sh create-release

# Create draft release
./scripts/release-manager.sh create-release --draft

# Upload additional assets
./scripts/release-manager.sh upload-assets v1.2.3 "extra-files/*"
```

## 🔍 Troubleshooting

### Common Issues

#### Build Failures

**Problem**: Android build fails with "Android SDK not found"
**Solution**: 
```bash
export ANDROID_SDK_ROOT=/path/to/android/sdk
./scripts/check-build-env.sh --platforms=android --fix
```

**Problem**: iOS build fails on non-macOS
**Solution**: iOS builds require macOS with Xcode installed

**Problem**: Web build works locally but fails on GitHub Pages
**Solution**: Check base-href setting:
```bash
./scripts/build-web.sh release --base-href=/repository-name/
```

#### Deployment Issues

**Problem**: GitHub Pages deployment fails
**Solution**: 
1. Enable GitHub Pages in repository settings
2. Set source to "Deploy from branch"
3. Select `gh-pages` branch

**Problem**: GitHub CLI authentication fails
**Solution**:
```bash
gh auth logout
gh auth login --web
```

#### Performance Issues

**Problem**: Builds are slow
**Solution**: Use parallel builds:
```bash
./scripts/build-all.sh --parallel --skip-tests
```

**Problem**: Out of disk space
**Solution**: Clean old artifacts:
```bash
./scripts/artifact-manager.sh clean
flutter clean
```

### Debug Mode

Enable verbose logging for any script:
```bash
export DEBUG=1
./scripts/build-all.sh
```

View build logs:
```bash
# Logs are saved to dist/logs/
cat dist/logs/build-android.log
cat dist/logs/build-web.log
```

## 🎯 Best Practices

### Development Workflow

1. **Regular Environment Checks**
   ```bash
   ./scripts/check-build-env.sh
   ```

2. **Use Debug Builds for Development**
   ```bash
   ./scripts/build-all.sh --build-type=debug --platforms=web
   ```

3. **Test Locally Before Deployment**
   ```bash
   # Test web build locally
   cd dist/web && python -m http.server 8000
   ```

### Release Workflow

1. **Version Bump**
   ```bash
   ./scripts/version-manager.sh bump minor
   ```

2. **Full Build and Test**
   ```bash
   ./scripts/build-all.sh --clean
   ./scripts/artifact-manager.sh verify
   ```

3. **Deploy as Draft First**
   ```bash
   ./scripts/deploy.sh --draft
   ```

4. **Test Everything, Then Publish**
   ```bash
   # Test web deployment
   # Test downloads from GitHub release
   # Then publish the draft release
   ```

### Performance Tips

- **Use parallel builds** when possible: `--parallel`
- **Skip tests during iteration**: `--skip-tests`
- **Build specific platforms only**: `--platforms=web,android`
- **Clean regularly**: `./scripts/artifact-manager.sh clean`

### Security

- **Never commit signing keys** or certificates
- **Use environment variables** for sensitive configuration
- **Review artifacts** before public release
- **Test on clean systems** before distribution

## 📊 File Structure

```
your-project/
├── scripts/                    # All build scripts
│   ├── build-android.sh       # Android builds
│   ├── build-ios.sh          # iOS builds
│   ├── build-web.sh          # Web builds
│   ├── build-desktop.sh      # Desktop builds
│   ├── build-all.sh          # Build orchestrator
│   ├── deploy.sh             # Main deployment
│   └── ...                   # Other utility scripts
├── dist/                      # Build outputs
│   ├── android/              # Android artifacts
│   ├── ios/                  # iOS artifacts
│   ├── web/                  # Web artifacts
│   ├── desktop/              # Desktop artifacts
│   ├── organized/            # Organized artifacts
│   └── logs/                 # Build logs
├── archives/                  # Deployment archives
└── BUILD_GUIDE.md            # This guide
```

## 🆘 Support

- **Environment Issues**: `./scripts/check-build-env.sh --fix`
- **Build Failures**: Check `dist/logs/` for detailed error messages
- **Deployment Problems**: Verify GitHub CLI setup with `gh auth status`
- **Performance**: Use `--parallel` and `--skip-tests` for faster builds

---

**🎮 Happy Building!** Your Dark Room game is now ready to be built and deployed across all platforms with zero cloud costs and full control over the build process.