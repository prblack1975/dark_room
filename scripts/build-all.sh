#!/bin/bash
# Main build orchestration script
# Usage: ./build-all.sh [options]
# Options:
#   --platforms=web,android,ios,desktop  (default: all available)
#   --build-type=debug|release           (default: release)
#   --parallel                           (build platforms in parallel)
#   --clean                              (clean before building)
#   --skip-tests                         (skip running tests)
#   --deploy                             (deploy after successful builds)

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_OUTPUT_DIR="$PROJECT_DIR/dist"
LOG_DIR="$BUILD_OUTPUT_DIR/logs"

# Default values
BUILD_TYPE="release"
PARALLEL_BUILD=false
CLEAN_BUILD=false
SKIP_TESTS=false
AUTO_DEPLOY=false
SELECTED_PLATFORMS=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_build() {
    echo -e "${PURPLE}[BUILD]${NC} $1"
}

log_deploy() {
    echo -e "${CYAN}[DEPLOY]${NC} $1"
}

# Parse command line arguments
parse_args() {
    for arg in "$@"; do
        case $arg in
            --platforms=*)
                SELECTED_PLATFORMS="${arg#*=}"
                ;;
            --build-type=*)
                BUILD_TYPE="${arg#*=}"
                ;;
            --parallel)
                PARALLEL_BUILD=true
                ;;
            --clean)
                CLEAN_BUILD=true
                ;;
            --skip-tests)
                SKIP_TESTS=true
                ;;
            --deploy)
                AUTO_DEPLOY=true
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_warning "Unknown argument: $arg"
                ;;
        esac
    done
}

show_help() {
    cat << EOF
Dark Room Game - Build Orchestration Script

Usage: $0 [options]

Options:
  --platforms=PLATFORMS    Comma-separated list of platforms to build
                          Available: web, android, ios, macos, linux, windows
                          Default: all available platforms for current OS
  
  --build-type=TYPE       Build type: debug or release (default: release)
  
  --parallel              Build platforms in parallel (faster but uses more resources)
  
  --clean                 Clean all build artifacts before starting
  
  --skip-tests            Skip running tests (faster but less safe)
  
  --deploy                Automatically deploy after successful builds
  
  --help, -h              Show this help message

Examples:
  $0                                    # Build all platforms for current OS
  $0 --platforms=web,android            # Build only web and Android
  $0 --parallel --build-type=debug      # Parallel debug builds
  $0 --clean --deploy                   # Clean build and auto-deploy

Platform Availability:
  - Web: Available on all systems
  - Android: Available on all systems (requires Android SDK)
  - iOS: macOS only (requires Xcode)
  - macOS: macOS only
  - Linux: Best on Linux, possible on macOS with Docker
  - Windows: Best on Windows, may work on other systems

EOF
}

# Determine available platforms based on current OS
get_available_platforms() {
    local platforms=()
    
    # Web is always available
    platforms+=("web")
    
    # Android is available if Android SDK is present
    if command -v android &> /dev/null || [[ -n "$ANDROID_SDK_ROOT" ]] || [[ -n "$ANDROID_HOME" ]]; then
        platforms+=("android")
    fi
    
    # Platform-specific availability
    case "$OSTYPE" in
        "darwin"*)
            platforms+=("ios" "macos")
            # Linux can be built on macOS with some setup
            platforms+=("linux")
            ;;
        "linux-gnu"*)
            platforms+=("linux")
            # Android needs SDK setup
            ;;
        "mingw"*|"cygwin"*|"msys"*)
            platforms+=("windows")
            ;;
    esac
    
    echo "${platforms[@]}"
}

# Validate selected platforms
validate_platforms() {
    local selected=($1)
    local available=($(get_available_platforms))
    local valid_platforms=()
    
    for platform in "${selected[@]}"; do
        if [[ " ${available[@]} " =~ " ${platform} " ]]; then
            valid_platforms+=("$platform")
        else
            log_warning "Platform '$platform' is not available on this system"
        fi
    done
    
    echo "${valid_platforms[@]}"
}

# Clean build artifacts
clean_builds() {
    log_info "Cleaning build artifacts..."
    
    # Remove Flutter build directory
    rm -rf "$PROJECT_DIR/build"
    
    # Remove dist directory
    rm -rf "$BUILD_OUTPUT_DIR"
    
    # Clean Flutter
    cd "$PROJECT_DIR"
    flutter clean
    
    log_success "Clean completed"
}

# Setup build environment
setup_environment() {
    log_info "Setting up build environment..."
    
    cd "$PROJECT_DIR"
    
    # Create output directories
    mkdir -p "$BUILD_OUTPUT_DIR"
    mkdir -p "$LOG_DIR"
    
    # Check Flutter installation
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter not found in PATH"
        exit 1
    fi
    
    # Check Dart installation
    if ! command -v dart &> /dev/null; then
        log_error "Dart not found in PATH"
        exit 1
    fi
    
    # Get Flutter and Dart versions
    FLUTTER_VERSION=$(flutter --version | head -n1 | cut -d' ' -f2)
    DART_VERSION=$(dart --version 2>&1 | cut -d' ' -f4)
    
    log_info "Flutter version: $FLUTTER_VERSION"
    log_info "Dart version: $DART_VERSION"
    
    # Get dependencies
    log_info "Getting dependencies..."
    flutter pub get
    
    # Run analysis and tests if not skipped
    if [[ "$SKIP_TESTS" != true ]]; then
        log_info "Running code analysis..."
        if ! flutter analyze --no-fatal-infos; then
            log_warning "Code analysis found issues"
        fi
        
        log_info "Running tests..."
        if ! flutter test; then
            log_warning "Some tests failed"
        fi
    else
        log_warning "Skipping tests as requested"
    fi
    
    log_success "Environment setup completed"
}

# Build a single platform
build_platform() {
    local platform=$1
    local log_file="$LOG_DIR/build-$platform.log"
    
    log_build "Building $platform..."
    
    case "$platform" in
        "web")
            "$SCRIPT_DIR/build-web.sh" "$BUILD_TYPE" > "$log_file" 2>&1
            ;;
        "android")
            "$SCRIPT_DIR/build-android.sh" "$BUILD_TYPE" "both" > "$log_file" 2>&1
            ;;
        "ios")
            "$SCRIPT_DIR/build-ios.sh" "$BUILD_TYPE" "device" > "$log_file" 2>&1
            ;;
        "macos"|"linux"|"windows")
            "$SCRIPT_DIR/build-desktop.sh" "$platform" "$BUILD_TYPE" > "$log_file" 2>&1
            ;;
        *)
            log_error "Unknown platform: $platform"
            return 1
            ;;
    esac
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "$platform build completed successfully"
        return 0
    else
        log_error "$platform build failed (exit code: $exit_code)"
        log_error "Check log file: $log_file"
        return 1
    fi
}

# Build platforms sequentially
build_sequential() {
    local platforms=($1)
    local failed_builds=()
    local successful_builds=()
    
    for platform in "${platforms[@]}"; do
        if build_platform "$platform"; then
            successful_builds+=("$platform")
        else
            failed_builds+=("$platform")
        fi
    done
    
    return_build_results "${successful_builds[@]}" "${failed_builds[@]}"
}

# Build platforms in parallel
build_parallel() {
    local platforms=($1)
    local pids=()
    local platform_pid_map=()
    
    log_info "Starting parallel builds for: ${platforms[*]}"
    
    # Start all builds in background
    for platform in "${platforms[@]}"; do
        build_platform "$platform" &
        local pid=$!
        pids+=($pid)
        platform_pid_map[$pid]="$platform"
    done
    
    # Wait for all builds and collect results
    local failed_builds=()
    local successful_builds=()
    
    for pid in "${pids[@]}"; do
        local platform="${platform_pid_map[$pid]}"
        if wait $pid; then
            successful_builds+=("$platform")
        else
            failed_builds+=("$platform")
        fi
    done
    
    return_build_results "${successful_builds[@]}" "${failed_builds[@]}"
}

# Report build results
return_build_results() {
    local successful=($1)
    local failed=($2)
    
    echo
    log_info "=== BUILD SUMMARY ==="
    
    if [[ ${#successful[@]} -gt 0 ]]; then
        log_success "Successful builds: ${successful[*]}"
    fi
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed builds: ${failed[*]}"
        echo
        log_info "Check log files in: $LOG_DIR"
        return 1
    else
        log_success "All builds completed successfully!"
        return 0
    fi
}

# Generate build report
generate_build_report() {
    local report_file="$BUILD_OUTPUT_DIR/build-report.json"
    local build_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local version=$(grep "version:" "$PROJECT_DIR/pubspec.yaml" | sed 's/version: //' | tr -d ' ')
    local commit_hash=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    
    # Collect platform information
    local platforms_json="["
    local first=true
    
    for platform_dir in "$BUILD_OUTPUT_DIR"/*; do
        if [[ -d "$platform_dir" && "$(basename "$platform_dir")" != "logs" ]]; then
            local platform=$(basename "$platform_dir")
            local build_info_file="$platform_dir/build-info-$platform.json"
            
            if [[ -f "$build_info_file" ]]; then
                if [[ "$first" != true ]]; then
                    platforms_json+=","
                fi
                platforms_json+=$(cat "$build_info_file")
                first=false
            fi
        fi
    done
    
    platforms_json+="]"
    
    # Generate main report
    cat > "$report_file" << EOF
{
  "buildTime": "$build_time",
  "version": "$version",
  "commitHash": "$commit_hash",
  "buildType": "$BUILD_TYPE",
  "parallelBuild": $PARALLEL_BUILD,
  "skippedTests": $SKIP_TESTS,
  "platforms": $platforms_json,
  "flutterVersion": "$FLUTTER_VERSION",
  "dartVersion": "$DART_VERSION",
  "buildMachine": "$(uname -a)"
}
EOF
    
    log_info "Build report generated: $report_file"
}

# Deploy builds
deploy_builds() {
    if [[ "$AUTO_DEPLOY" != true ]]; then
        return 0
    fi
    
    log_deploy "Starting deployment process..."
    
    # Check if deploy script exists
    local deploy_script="$SCRIPT_DIR/deploy.sh"
    if [[ -f "$deploy_script" ]]; then
        log_deploy "Running deployment script..."
        "$deploy_script" "$BUILD_TYPE"
    else
        log_warning "Deploy script not found: $deploy_script"
        log_info "Deployment must be done manually"
    fi
}

# Main execution
main() {
    echo "Dark Room Game - Build Orchestration"
    echo "===================================="
    echo
    
    # Parse arguments
    parse_args "$@"
    
    # Validate build type
    if [[ "$BUILD_TYPE" != "debug" && "$BUILD_TYPE" != "release" ]]; then
        log_error "Invalid build type: $BUILD_TYPE. Use 'debug' or 'release'"
        exit 1
    fi
    
    # Determine platforms to build
    local platforms_to_build
    if [[ -n "$SELECTED_PLATFORMS" ]]; then
        IFS=',' read -ra PLATFORM_ARRAY <<< "$SELECTED_PLATFORMS"
        platforms_to_build=($(validate_platforms "${PLATFORM_ARRAY[*]}"))
    else
        platforms_to_build=($(get_available_platforms))
    fi
    
    if [[ ${#platforms_to_build[@]} -eq 0 ]]; then
        log_error "No valid platforms to build"
        exit 1
    fi
    
    log_info "Platforms to build: ${platforms_to_build[*]}"
    log_info "Build type: $BUILD_TYPE"
    log_info "Parallel build: $PARALLEL_BUILD"
    
    # Clean if requested
    if [[ "$CLEAN_BUILD" == true ]]; then
        clean_builds
    fi
    
    # Setup environment
    setup_environment
    
    # Build platforms
    if [[ "$PARALLEL_BUILD" == true ]]; then
        if ! build_parallel "${platforms_to_build[*]}"; then
            exit 1
        fi
    else
        if ! build_sequential "${platforms_to_build[*]}"; then
            exit 1
        fi
    fi
    
    # Generate build report
    generate_build_report
    
    # Deploy if requested
    deploy_builds
    
    log_success "Build orchestration completed successfully!"
    log_info "Build artifacts available in: $BUILD_OUTPUT_DIR"
}

# Execute main function
main "$@"