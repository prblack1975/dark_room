#!/bin/bash
# Build script for Android platform
# Usage: ./build-android.sh [debug|release] [apk|aab|both]

set -e

# Configuration
BUILD_TYPE=${1:-release}
PACKAGE_TYPE=${2:-both}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_OUTPUT_DIR="$PROJECT_DIR/dist/android"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate build type
if [[ "$BUILD_TYPE" != "debug" && "$BUILD_TYPE" != "release" ]]; then
    log_error "Invalid build type: $BUILD_TYPE. Use 'debug' or 'release'"
    exit 1
fi

# Validate package type
if [[ "$PACKAGE_TYPE" != "apk" && "$PACKAGE_TYPE" != "aab" && "$PACKAGE_TYPE" != "both" ]]; then
    log_error "Invalid package type: $PACKAGE_TYPE. Use 'apk', 'aab', or 'both'"
    exit 1
fi

log_info "Starting Android build..."
log_info "Build type: $BUILD_TYPE"
log_info "Package type: $PACKAGE_TYPE"

# Change to project directory
cd "$PROJECT_DIR"

# Check if Android SDK is available
if ! command -v android &> /dev/null; then
    if [[ -z "$ANDROID_SDK_ROOT" && -z "$ANDROID_HOME" ]]; then
        log_warning "Android SDK not found in PATH and ANDROID_SDK_ROOT/ANDROID_HOME not set"
        log_info "Attempting to use Flutter's Android SDK..."
    fi
fi

# Check Java version
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [[ "$JAVA_VERSION" -lt 11 ]]; then
        log_warning "Java version $JAVA_VERSION detected. Java 11+ recommended for Android builds"
    fi
else
    log_error "Java not found. Please install Java 11+ for Android development"
    exit 1
fi

# Clean previous builds
log_info "Cleaning previous builds..."
flutter clean

# Get dependencies
log_info "Getting dependencies..."
flutter pub get

# Run code analysis
log_info "Running code analysis..."
if ! flutter analyze --no-fatal-infos; then
    log_warning "Code analysis found issues. Continuing with build..."
fi

# Run tests
log_info "Running tests..."
if ! flutter test; then
    log_warning "Some tests failed. Continuing with build..."
fi

# Create output directory
mkdir -p "$BUILD_OUTPUT_DIR"

# Build APK if requested
if [[ "$PACKAGE_TYPE" == "apk" || "$PACKAGE_TYPE" == "both" ]]; then
    log_info "Building Android APK ($BUILD_TYPE)..."
    
    if [[ "$BUILD_TYPE" == "release" ]]; then
        flutter build apk --release
        APK_SOURCE="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
        APK_TARGET="$BUILD_OUTPUT_DIR/dark_room-android-release.apk"
    else
        flutter build apk --debug
        APK_SOURCE="$PROJECT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
        APK_TARGET="$BUILD_OUTPUT_DIR/dark_room-android-debug.apk"
    fi
    
    if [[ -f "$APK_SOURCE" ]]; then
        cp "$APK_SOURCE" "$APK_TARGET"
        APK_SIZE=$(du -h "$APK_TARGET" | cut -f1)
        log_success "APK built successfully: $APK_TARGET ($APK_SIZE)"
    else
        log_error "APK build failed - output file not found"
        exit 1
    fi
fi

# Build AAB if requested
if [[ "$PACKAGE_TYPE" == "aab" || "$PACKAGE_TYPE" == "both" ]]; then
    log_info "Building Android App Bundle ($BUILD_TYPE)..."
    
    if [[ "$BUILD_TYPE" == "release" ]]; then
        flutter build appbundle --release
        AAB_SOURCE="$PROJECT_DIR/build/app/outputs/bundle/release/app-release.aab"
        AAB_TARGET="$BUILD_OUTPUT_DIR/dark_room-android-release.aab"
    else
        flutter build appbundle --debug
        AAB_SOURCE="$PROJECT_DIR/build/app/outputs/bundle/debug/app-debug.aab"
        AAB_TARGET="$BUILD_OUTPUT_DIR/dark_room-android-debug.aab"
    fi
    
    if [[ -f "$AAB_SOURCE" ]]; then
        cp "$AAB_SOURCE" "$AAB_TARGET"
        AAB_SIZE=$(du -h "$AAB_TARGET" | cut -f1)
        log_success "AAB built successfully: $AAB_TARGET ($AAB_SIZE)"
    else
        log_error "AAB build failed - output file not found"
        exit 1
    fi
fi

# Generate build info
BUILD_INFO_FILE="$BUILD_OUTPUT_DIR/build-info-android.json"
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

cat > "$BUILD_INFO_FILE" << EOF
{
  "platform": "android",
  "version": "$VERSION",
  "buildType": "$BUILD_TYPE",
  "packageType": "$PACKAGE_TYPE",
  "buildTime": "$BUILD_TIME",
  "commitHash": "$COMMIT_HASH",
  "dartVersion": "$(dart --version 2>&1 | cut -d' ' -f4)",
  "flutterVersion": "$(flutter --version | head -n1 | cut -d' ' -f2)"
}
EOF

log_success "Android build completed successfully!"
log_info "Build artifacts saved to: $BUILD_OUTPUT_DIR"
log_info "Build info: $BUILD_INFO_FILE"