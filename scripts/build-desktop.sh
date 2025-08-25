#!/bin/bash
# Build script for Desktop platforms (macOS, Windows, Linux)
# Usage: ./build-desktop.sh [platform] [debug|release]
# Platform: macos, windows, linux, or all

set -e

# Configuration
PLATFORM=${1:-$(uname | tr '[:upper:]' '[:lower:]')}
BUILD_TYPE=${2:-release}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_OUTPUT_DIR="$PROJECT_DIR/dist/desktop"

# Map platform names
case "$PLATFORM" in
    "darwin") PLATFORM="macos" ;;
    "linux") PLATFORM="linux" ;;
    "mingw"*|"cygwin"*|"msys"*) PLATFORM="windows" ;;
esac

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

# Validate platform
if [[ "$PLATFORM" != "macos" && "$PLATFORM" != "windows" && "$PLATFORM" != "linux" && "$PLATFORM" != "all" ]]; then
    log_error "Invalid platform: $PLATFORM. Use 'macos', 'windows', 'linux', or 'all'"
    exit 1
fi

# Validate build type
if [[ "$BUILD_TYPE" != "debug" && "$BUILD_TYPE" != "release" ]]; then
    log_error "Invalid build type: $BUILD_TYPE. Use 'debug' or 'release'"
    exit 1
fi

# Function to check platform requirements
check_platform_requirements() {
    local platform=$1
    
    case "$platform" in
        "macos")
            if [[ "$OSTYPE" != "darwin"* ]]; then
                log_error "macOS builds require macOS"
                return 1
            fi
            ;;
        "windows")
            if [[ "$OSTYPE" == "darwin"* ]]; then
                log_warning "Windows builds on macOS may require additional setup"
            elif [[ "$OSTYPE" != "mingw"* && "$OSTYPE" != "cygwin"* && "$OSTYPE" != "msys"* ]]; then
                log_warning "Windows builds on $OSTYPE may not be supported"
            fi
            ;;
        "linux")
            if [[ "$OSTYPE" == "darwin"* ]]; then
                log_warning "Linux builds on macOS may require Docker or cross-compilation"
            elif [[ "$OSTYPE" != "linux-gnu"* ]]; then
                log_warning "Linux builds on $OSTYPE may require additional setup"
            fi
            ;;
    esac
    return 0
}

# Function to build for a specific platform
build_platform() {
    local platform=$1
    local build_type=$2
    
    log_info "Building for $platform ($build_type)..."
    
    # Check platform requirements
    if ! check_platform_requirements "$platform"; then
        log_error "Platform requirements not met for $platform"
        return 1
    fi
    
    # Platform-specific setup
    case "$platform" in
        "linux")
            # Check Linux dependencies
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                log_info "Checking Linux build dependencies..."
                if ! pkg-config --exists gtk+-3.0; then
                    log_error "GTK+3 development libraries not found. Install with: sudo apt-get install libgtk-3-dev"
                    return 1
                fi
            fi
            ;;
        "windows")
            # Windows-specific checks would go here
            ;;
        "macos")
            # macOS-specific checks would go here
            ;;
    esac
    
    # Enable desktop support if not already enabled
    flutter config --enable-${platform}-desktop 2>/dev/null || true
    
    # Build command
    local build_cmd
    if [[ "$build_type" == "release" ]]; then
        build_cmd="flutter build $platform --release"
    else
        build_cmd="flutter build $platform --debug"
    fi
    
    log_info "Executing: $build_cmd"
    if ! eval "$build_cmd"; then
        log_error "Build failed for $platform"
        return 1
    fi
    
    # Create output directory for this platform
    local platform_output_dir="$BUILD_OUTPUT_DIR/$platform"
    mkdir -p "$platform_output_dir"
    
    # Copy and archive build artifacts
    local build_source
    local archive_name
    
    case "$platform" in
        "macos")
            build_source="$PROJECT_DIR/build/macos/Build/Products/Release/dark_room.app"
            if [[ "$build_type" == "debug" ]]; then
                build_source="$PROJECT_DIR/build/macos/Build/Products/Debug/dark_room.app"
            fi
            archive_name="dark_room-macos-$build_type.tar.gz"
            
            if [[ -d "$build_source" ]]; then
                cd "$(dirname "$build_source")"
                tar -czf "$platform_output_dir/$archive_name" "$(basename "$build_source")"
                cd "$PROJECT_DIR"
            else
                log_error "macOS build artifact not found: $build_source"
                return 1
            fi
            ;;
            
        "windows")
            build_source="$PROJECT_DIR/build/windows/x64/runner/Release"
            if [[ "$build_type" == "debug" ]]; then
                build_source="$PROJECT_DIR/build/windows/x64/runner/Debug"
            fi
            archive_name="dark_room-windows-$build_type.zip"
            
            if [[ -d "$build_source" ]]; then
                cd "$build_source"
                if command -v zip &> /dev/null; then
                    zip -r "$platform_output_dir/$archive_name" *
                else
                    # Fallback to tar on systems without zip
                    tar -czf "$platform_output_dir/dark_room-windows-$build_type.tar.gz" *
                    archive_name="dark_room-windows-$build_type.tar.gz"
                fi
                cd "$PROJECT_DIR"
            else
                log_error "Windows build artifact not found: $build_source"
                return 1
            fi
            ;;
            
        "linux")
            build_source="$PROJECT_DIR/build/linux/x64/release/bundle"
            if [[ "$build_type" == "debug" ]]; then
                build_source="$PROJECT_DIR/build/linux/x64/debug/bundle"
            fi
            archive_name="dark_room-linux-$build_type.tar.gz"
            
            if [[ -d "$build_source" ]]; then
                cd "$build_source"
                tar -czf "$platform_output_dir/$archive_name" *
                cd "$PROJECT_DIR"
            else
                log_error "Linux build artifact not found: $build_source"
                return 1
            fi
            ;;
    esac
    
    # Calculate archive size
    local archive_path="$platform_output_dir/$archive_name"
    if [[ -f "$archive_path" ]]; then
        local archive_size=$(du -h "$archive_path" | cut -f1)
        log_success "$platform build completed: $archive_name ($archive_size)"
        
        # Generate platform-specific build info
        local build_info_file="$platform_output_dir/build-info-$platform.json"
        local version=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
        local build_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        local commit_hash=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
        
        cat > "$build_info_file" << EOF
{
  "platform": "$platform",
  "version": "$version",
  "buildType": "$build_type",
  "buildTime": "$build_time",
  "commitHash": "$commit_hash",
  "archiveName": "$archive_name",
  "archiveSize": "$archive_size",
  "dartVersion": "$(dart --version 2>&1 | cut -d' ' -f4)",
  "flutterVersion": "$(flutter --version | head -n1 | cut -d' ' -f2)"
}
EOF
        
        return 0
    else
        log_error "Failed to create archive for $platform"
        return 1
    fi
}

# Main execution
log_info "Starting Desktop build..."
log_info "Platform(s): $PLATFORM"
log_info "Build type: $BUILD_TYPE"

# Change to project directory
cd "$PROJECT_DIR"

# Common setup
log_info "Cleaning previous builds..."
flutter clean

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

# Build platforms
if [[ "$PLATFORM" == "all" ]]; then
    # Build all supported platforms for current OS
    PLATFORMS_TO_BUILD=()
    
    case "$OSTYPE" in
        "darwin"*)
            PLATFORMS_TO_BUILD=("macos" "linux")
            log_info "Building macOS and Linux (Windows may require additional setup)"
            ;;
        "linux-gnu"*)
            PLATFORMS_TO_BUILD=("linux")
            log_info "Building Linux only (other platforms require different OS)"
            ;;
        "mingw"*|"cygwin"*|"msys"*)
            PLATFORMS_TO_BUILD=("windows")
            log_info "Building Windows only"
            ;;
        *)
            log_error "Unsupported OS for desktop builds: $OSTYPE"
            exit 1
            ;;
    esac
    
    for platform in "${PLATFORMS_TO_BUILD[@]}"; do
        if ! build_platform "$platform" "$BUILD_TYPE"; then
            log_error "Failed to build $platform"
            # Continue with other platforms rather than failing completely
        fi
    done
else
    # Build specific platform
    if ! build_platform "$PLATFORM" "$BUILD_TYPE"; then
        log_error "Build failed for $PLATFORM"
        exit 1
    fi
fi

log_success "Desktop build process completed!"
log_info "Build artifacts saved to: $BUILD_OUTPUT_DIR"

# Show summary
log_info "Build Summary:"
find "$BUILD_OUTPUT_DIR" -name "*.tar.gz" -o -name "*.zip" | while read -r archive; do
    local size=$(du -h "$archive" | cut -f1)
    local name=$(basename "$archive")
    log_info "  - $name ($size)"
done