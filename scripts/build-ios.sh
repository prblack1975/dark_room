#!/bin/bash
# Build script for iOS platform
# Usage: ./build-ios.sh [debug|release] [simulator|device]

set -e

# Configuration
BUILD_TYPE=${1:-release}
TARGET_TYPE=${2:-device}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_OUTPUT_DIR="$PROJECT_DIR/dist/ios"

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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "iOS builds require macOS. Current OS: $OSTYPE"
    exit 1
fi

# Validate build type
if [[ "$BUILD_TYPE" != "debug" && "$BUILD_TYPE" != "release" ]]; then
    log_error "Invalid build type: $BUILD_TYPE. Use 'debug' or 'release'"
    exit 1
fi

# Validate target type
if [[ "$TARGET_TYPE" != "simulator" && "$TARGET_TYPE" != "device" ]]; then
    log_error "Invalid target type: $TARGET_TYPE. Use 'simulator' or 'device'"
    exit 1
fi

log_info "Starting iOS build..."
log_info "Build type: $BUILD_TYPE"
log_info "Target type: $TARGET_TYPE"

# Change to project directory
cd "$PROJECT_DIR"

# Check Xcode installation
if ! command -v xcodebuild &> /dev/null; then
    log_error "Xcode command line tools not found. Please install Xcode and command line tools"
    exit 1
fi

# Check Xcode version
XCODE_VERSION=$(xcodebuild -version | head -n1 | cut -d' ' -f2)
log_info "Xcode version: $XCODE_VERSION"

# List available iOS SDKs for information
log_info "Available iOS SDKs:"
xcodebuild -showsdks | grep iphoneos || log_warning "No iOS SDKs found"

# Check CocoaPods installation
if ! command -v pod &> /dev/null; then
    log_warning "CocoaPods not found. Installing..."
    sudo gem install cocoapods
fi

# Clean previous builds
log_info "Cleaning previous builds..."
flutter clean

# Get dependencies
log_info "Getting dependencies..."
flutter pub get

# Update CocoaPods
log_info "Updating CocoaPods dependencies..."
cd ios
pod install --repo-update
cd ..

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

# Build for iOS
log_info "Building iOS app ($BUILD_TYPE, $TARGET_TYPE)..."

if [[ "$TARGET_TYPE" == "simulator" ]]; then
    # Build for simulator
    if [[ "$BUILD_TYPE" == "release" ]]; then
        flutter build ios --release --simulator
        BUILD_PATH="$PROJECT_DIR/build/ios/iphonesimulator/Runner.app"
        OUTPUT_NAME="dark_room-ios-simulator-release.app.tar.gz"
    else
        flutter build ios --debug --simulator
        BUILD_PATH="$PROJECT_DIR/build/ios/iphonesimulator/Runner.app"
        OUTPUT_NAME="dark_room-ios-simulator-debug.app.tar.gz"
    fi
else
    # Build for device (no code signing for CI/CD)
    if [[ "$BUILD_TYPE" == "release" ]]; then
        flutter build ios --release --no-codesign
        BUILD_PATH="$PROJECT_DIR/build/ios/iphoneos/Runner.app"
        OUTPUT_NAME="dark_room-ios-device-release.app.tar.gz"
    else
        flutter build ios --debug --no-codesign
        BUILD_PATH="$PROJECT_DIR/build/ios/iphoneos/Runner.app"
        OUTPUT_NAME="dark_room-ios-device-debug.app.tar.gz"
    fi
fi

# Check if build succeeded
if [[ ! -d "$BUILD_PATH" ]]; then
    log_error "iOS build failed - output directory not found: $BUILD_PATH"
    exit 1
fi

# Create archive
OUTPUT_PATH="$BUILD_OUTPUT_DIR/$OUTPUT_NAME"
log_info "Creating archive: $OUTPUT_NAME"

cd "$(dirname "$BUILD_PATH")"
tar -czf "$OUTPUT_PATH" "$(basename "$BUILD_PATH")"
cd "$PROJECT_DIR"

if [[ -f "$OUTPUT_PATH" ]]; then
    ARCHIVE_SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)
    log_success "iOS build completed successfully: $OUTPUT_PATH ($ARCHIVE_SIZE)"
else
    log_error "Failed to create archive"
    exit 1
fi

# Generate build info
BUILD_INFO_FILE="$BUILD_OUTPUT_DIR/build-info-ios.json"
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

cat > "$BUILD_INFO_FILE" << EOF
{
  "platform": "ios",
  "version": "$VERSION",
  "buildType": "$BUILD_TYPE",
  "targetType": "$TARGET_TYPE",
  "buildTime": "$BUILD_TIME",
  "commitHash": "$COMMIT_HASH",
  "xcodeVersion": "$XCODE_VERSION",
  "dartVersion": "$(dart --version 2>&1 | cut -d' ' -f4)",
  "flutterVersion": "$(flutter --version | head -n1 | cut -d' ' -f2)",
  "codesigning": false,
  "note": "This build is unsigned and requires proper signing for distribution"
}
EOF

log_success "iOS build completed successfully!"
log_info "Build artifacts saved to: $BUILD_OUTPUT_DIR"
log_info "Build info: $BUILD_INFO_FILE"

if [[ "$TARGET_TYPE" == "device" ]]; then
    log_warning "Device build is unsigned and will require proper code signing for distribution"
    log_info "For App Store distribution, you'll need to sign with your developer certificate"
fi