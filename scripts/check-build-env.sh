#!/bin/bash
# Environment validation and dependency checking script
# Usage: ./check-build-env.sh [--platforms=web,android,ios,desktop] [--fix]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CHECK_PLATFORMS=""
AUTO_FIX=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_check() {
    echo -e "${PURPLE}[CHECK]${NC} $1"
}

# Parse command line arguments
parse_args() {
    for arg in "$@"; do
        case $arg in
            --platforms=*)
                CHECK_PLATFORMS="${arg#*=}"
                ;;
            --fix)
                AUTO_FIX=true
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
Dark Room Game - Build Environment Checker

Usage: $0 [options]

Options:
  --platforms=PLATFORMS    Comma-separated list of platforms to check
                          Available: web, android, ios, macos, linux, windows
                          Default: all available platforms for current OS
  
  --fix                   Attempt to automatically fix issues where possible
  
  --help, -h              Show this help message

Examples:
  $0                                    # Check all platforms for current OS
  $0 --platforms=web,android            # Check only web and Android
  $0 --fix                              # Check and attempt auto-fixes

This script checks:
  - Flutter and Dart installation
  - Platform-specific SDKs and tools
  - Build dependencies
  - Project configuration
  - Network connectivity for package downloads

EOF
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Flutter installation
check_flutter() {
    log_check "Checking Flutter installation..."
    
    if ! command_exists flutter; then
        log_error "Flutter not found in PATH"
        if [[ "$AUTO_FIX" == true ]]; then
            log_info "Auto-fix: Please install Flutter manually from https://flutter.dev"
        fi
        return 1
    fi
    
    local flutter_version=$(flutter --version | head -n1 | cut -d' ' -f2)
    log_success "Flutter $flutter_version found"
    
    # Check Flutter doctor
    log_info "Running Flutter doctor..."
    if flutter doctor | grep -q "No issues found"; then
        log_success "Flutter doctor reports no issues"
    else
        log_warning "Flutter doctor found some issues:"
        flutter doctor
    fi
    
    return 0
}

# Check Dart installation
check_dart() {
    log_check "Checking Dart installation..."
    
    if ! command_exists dart; then
        log_error "Dart not found in PATH"
        return 1
    fi
    
    local dart_version=$(dart --version 2>&1 | cut -d' ' -f4)
    log_success "Dart $dart_version found"
    
    return 0
}

# Check Git installation
check_git() {
    log_check "Checking Git installation..."
    
    if ! command_exists git; then
        log_error "Git not found in PATH"
        if [[ "$AUTO_FIX" == true ]]; then
            log_info "Auto-fix: Installing Git..."
            case "$OSTYPE" in
                "darwin"*)
                    if command_exists brew; then
                        brew install git
                    else
                        log_error "Please install Git manually or install Homebrew first"
                        return 1
                    fi
                    ;;
                "linux-gnu"*)
                    if command_exists apt-get; then
                        sudo apt-get update && sudo apt-get install -y git
                    elif command_exists yum; then
                        sudo yum install -y git
                    else
                        log_error "Please install Git manually"
                        return 1
                    fi
                    ;;
                *)
                    log_error "Please install Git manually"
                    return 1
                    ;;
            esac
        fi
        return 1
    fi
    
    local git_version=$(git --version | cut -d' ' -f3)
    log_success "Git $git_version found"
    
    # Check if we're in a git repository
    cd "$PROJECT_DIR"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        log_success "Project is in a Git repository"
    else
        log_warning "Project is not in a Git repository"
    fi
    
    return 0
}

# Check web platform requirements
check_web_platform() {
    log_check "Checking web platform requirements..."
    
    # Check if web support is enabled
    if flutter config | grep -q "enable-web: true"; then
        log_success "Flutter web support is enabled"
    else
        log_warning "Flutter web support is disabled"
        if [[ "$AUTO_FIX" == true ]]; then
            log_info "Auto-fix: Enabling web support..."
            flutter config --enable-web
            log_success "Web support enabled"
        fi
    fi
    
    # Check Chrome installation for testing
    local chrome_found=false
    local chrome_paths=(
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        "/usr/bin/google-chrome"
        "/usr/bin/chromium-browser"
        "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
        "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe"
    )
    
    for chrome_path in "${chrome_paths[@]}"; do
        if [[ -f "$chrome_path" ]] || command_exists google-chrome || command_exists chromium-browser; then
            chrome_found=true
            break
        fi
    done
    
    if [[ "$chrome_found" == true ]]; then
        log_success "Chrome/Chromium found for web testing"
    else
        log_warning "Chrome/Chromium not found - web testing may not work"
    fi
    
    return 0
}

# Check Android platform requirements
check_android_platform() {
    log_check "Checking Android platform requirements..."
    
    # Check Android SDK
    if [[ -n "$ANDROID_SDK_ROOT" ]] || [[ -n "$ANDROID_HOME" ]]; then
        local sdk_path="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
        log_success "Android SDK found at: $sdk_path"
    elif command_exists android; then
        log_success "Android SDK found in PATH"
    else
        log_error "Android SDK not found"
        log_info "Set ANDROID_SDK_ROOT environment variable or install Android SDK"
        return 1
    fi
    
    # Check Java version
    if command_exists java; then
        local java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2 | cut -d'.' -f1)
        if [[ "$java_version" -ge 11 ]]; then
            log_success "Java $java_version found (compatible)"
        else
            log_warning "Java $java_version found (Java 11+ recommended)"
        fi
    else
        log_error "Java not found - required for Android builds"
        return 1
    fi
    
    # Check Android licenses
    if flutter doctor | grep -q "Android license status unknown"; then
        log_warning "Android licenses not accepted"
        if [[ "$AUTO_FIX" == true ]]; then
            log_info "Auto-fix: Accepting Android licenses..."
            flutter doctor --android-licenses
        fi
    else
        log_success "Android licenses accepted"
    fi
    
    return 0
}

# Check iOS platform requirements
check_ios_platform() {
    log_check "Checking iOS platform requirements..."
    
    # iOS builds only work on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "iOS builds require macOS (current: $OSTYPE)"
        return 1
    fi
    
    # Check Xcode
    if ! command_exists xcodebuild; then
        log_error "Xcode command line tools not found"
        if [[ "$AUTO_FIX" == true ]]; then
            log_info "Auto-fix: Installing Xcode command line tools..."
            xcode-select --install
        fi
        return 1
    fi
    
    local xcode_version=$(xcodebuild -version | head -n1 | cut -d' ' -f2)
    log_success "Xcode $xcode_version found"
    
    # Check iOS simulators
    if xcrun simctl list devices | grep -q "iOS"; then
        log_success "iOS simulators available"
    else
        log_warning "No iOS simulators found"
    fi
    
    # Check CocoaPods
    if command_exists pod; then
        local pod_version=$(pod --version)
        log_success "CocoaPods $pod_version found"
    else
        log_warning "CocoaPods not found"
        if [[ "$AUTO_FIX" == true ]]; then
            log_info "Auto-fix: Installing CocoaPods..."
            sudo gem install cocoapods
        fi
    fi
    
    return 0
}

# Check macOS platform requirements
check_macos_platform() {
    log_check "Checking macOS platform requirements..."
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "macOS builds require macOS (current: $OSTYPE)"
        return 1
    fi
    
    # Check if macOS desktop support is enabled
    if flutter config | grep -q "enable-macos-desktop: true"; then
        log_success "Flutter macOS desktop support is enabled"
    else
        log_warning "Flutter macOS desktop support is disabled"
        if [[ "$AUTO_FIX" == true ]]; then
            log_info "Auto-fix: Enabling macOS desktop support..."
            flutter config --enable-macos-desktop
        fi
    fi
    
    # Check Xcode (also needed for macOS)
    if ! command_exists xcodebuild; then
        log_error "Xcode command line tools not found"
        return 1
    fi
    
    log_success "macOS build environment ready"
    return 0
}

# Check Linux platform requirements
check_linux_platform() {
    log_check "Checking Linux platform requirements..."
    
    # Check if Linux desktop support is enabled
    if flutter config | grep -q "enable-linux-desktop: true"; then
        log_success "Flutter Linux desktop support is enabled"
    else
        log_warning "Flutter Linux desktop support is disabled"
        if [[ "$AUTO_FIX" == true ]]; then
            log_info "Auto-fix: Enabling Linux desktop support..."
            flutter config --enable-linux-desktop
        fi
    fi
    
    # Check Linux build dependencies (mainly for Linux systems)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        local missing_deps=()
        
        # Check for required packages
        if ! pkg-config --exists gtk+-3.0; then
            missing_deps+=("libgtk-3-dev")
        fi
        
        if ! command_exists clang; then
            missing_deps+=("clang")
        fi
        
        if ! command_exists cmake; then
            missing_deps+=("cmake")
        fi
        
        if ! command_exists ninja; then
            missing_deps+=("ninja-build")
        fi
        
        if [[ ${#missing_deps[@]} -gt 0 ]]; then
            log_warning "Missing Linux dependencies: ${missing_deps[*]}"
            if [[ "$AUTO_FIX" == true ]]; then
                log_info "Auto-fix: Installing missing dependencies..."
                if command_exists apt-get; then
                    sudo apt-get update
                    sudo apt-get install -y "${missing_deps[@]}"
                elif command_exists yum; then
                    sudo yum install -y "${missing_deps[@]}"
                else
                    log_error "Please install missing dependencies manually"
                    return 1
                fi
            fi
        else
            log_success "All Linux dependencies are available"
        fi
    else
        log_info "Cross-compilation for Linux from $OSTYPE (may require Docker)"
    fi
    
    return 0
}

# Check Windows platform requirements
check_windows_platform() {
    log_check "Checking Windows platform requirements..."
    
    # Check if Windows desktop support is enabled
    if flutter config | grep -q "enable-windows-desktop: true"; then
        log_success "Flutter Windows desktop support is enabled"
    else
        log_warning "Flutter Windows desktop support is disabled"
        if [[ "$AUTO_FIX" == true ]]; then
            log_info "Auto-fix: Enabling Windows desktop support..."
            flutter config --enable-windows-desktop
        fi
    fi
    
    # Platform-specific checks
    case "$OSTYPE" in
        "mingw"*|"cygwin"*|"msys"*)
            log_success "Running on Windows"
            # Check Visual Studio Build Tools
            if command_exists cl; then
                log_success "Microsoft Visual C++ compiler found"
            else
                log_warning "Microsoft Visual C++ compiler not found"
                log_info "Install Visual Studio Build Tools or Visual Studio Community"
            fi
            ;;
        *)
            log_info "Cross-compilation for Windows from $OSTYPE (may require additional setup)"
            ;;
    esac
    
    return 0
}

# Check project dependencies
check_project_dependencies() {
    log_check "Checking project dependencies..."
    
    cd "$PROJECT_DIR"
    
    # Check pubspec.yaml exists
    if [[ -f "pubspec.yaml" ]]; then
        log_success "pubspec.yaml found"
        
        # Check version format
        if grep -q "version: [0-9]\+\.[0-9]\+\.[0-9]\++[0-9]\+" pubspec.yaml; then
            log_success "Version format is correct"
        else
            log_warning "Version format may need adjustment for build numbering"
        fi
    else
        log_error "pubspec.yaml not found - not a Flutter project?"
        return 1
    fi
    
    # Check if pub get is needed
    if [[ ! -d ".dart_tool" ]] || [[ "pubspec.yaml" -nt ".dart_tool/package_config.json" ]]; then
        log_warning "Dependencies need to be fetched"
        if [[ "$AUTO_FIX" == true ]]; then
            log_info "Auto-fix: Running flutter pub get..."
            flutter pub get
            log_success "Dependencies updated"
        fi
    else
        log_success "Dependencies are up to date"
    fi
    
    return 0
}

# Check network connectivity
check_network() {
    log_check "Checking network connectivity..."
    
    # Check if we can reach pub.dev
    if ping -c 1 pub.dev > /dev/null 2>&1; then
        log_success "Can reach pub.dev (Dart package repository)"
    else
        log_warning "Cannot reach pub.dev - package downloads may fail"
    fi
    
    # Check if we can reach GitHub (for Git operations)
    if ping -c 1 github.com > /dev/null 2>&1; then
        log_success "Can reach GitHub"
    else
        log_warning "Cannot reach GitHub - Git operations may fail"
    fi
    
    return 0
}

# Main platform checking function
check_platform() {
    local platform=$1
    local result=0
    
    case "$platform" in
        "web")
            check_web_platform || result=1
            ;;
        "android")
            check_android_platform || result=1
            ;;
        "ios")
            check_ios_platform || result=1
            ;;
        "macos")
            check_macos_platform || result=1
            ;;
        "linux")
            check_linux_platform || result=1
            ;;
        "windows")
            check_windows_platform || result=1
            ;;
        *)
            log_error "Unknown platform: $platform"
            return 1
            ;;
    esac
    
    return $result
}

# Generate environment report
generate_report() {
    local report_file="$PROJECT_DIR/build-environment-report.json"
    local check_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat > "$report_file" << EOF
{
  "checkTime": "$check_time",
  "system": {
    "os": "$OSTYPE",
    "arch": "$(uname -m)",
    "kernel": "$(uname -r)"
  },
  "flutter": {
    "version": "$(flutter --version | head -n1 | cut -d' ' -f2 2>/dev/null || echo 'not found')",
    "channel": "$(flutter --version | grep channel | cut -d' ' -f5 2>/dev/null || echo 'unknown')"
  },
  "dart": {
    "version": "$(dart --version 2>&1 | cut -d' ' -f4 2>/dev/null || echo 'not found')"
  },
  "git": {
    "version": "$(git --version 2>/dev/null | cut -d' ' -f3 || echo 'not found')"
  }
}
EOF
    
    log_info "Environment report saved to: $report_file"
}

# Main execution
main() {
    echo "Dark Room Game - Build Environment Checker"
    echo "=========================================="
    echo
    
    # Parse arguments
    parse_args "$@"
    
    local overall_result=0
    
    # Core checks
    check_flutter || overall_result=1
    check_dart || overall_result=1
    check_git || overall_result=1
    check_project_dependencies || overall_result=1
    check_network
    
    echo
    
    # Platform checks
    local platforms_to_check=()
    if [[ -n "$CHECK_PLATFORMS" ]]; then
        IFS=',' read -ra platforms_to_check <<< "$CHECK_PLATFORMS"
    else
        # Default to available platforms
        case "$OSTYPE" in
            "darwin"*)
                platforms_to_check=("web" "android" "ios" "macos" "linux")
                ;;
            "linux-gnu"*)
                platforms_to_check=("web" "android" "linux")
                ;;
            "mingw"*|"cygwin"*|"msys"*)
                platforms_to_check=("web" "android" "windows")
                ;;
            *)
                platforms_to_check=("web")
                ;;
        esac
    fi
    
    log_info "Checking platforms: ${platforms_to_check[*]}"
    echo
    
    for platform in "${platforms_to_check[@]}"; do
        check_platform "$platform" || overall_result=1
        echo
    done
    
    # Generate report
    generate_report
    
    # Summary
    if [[ $overall_result -eq 0 ]]; then
        log_success "All environment checks passed!"
        log_info "Your system is ready for building Dark Room Game"
    else
        log_warning "Some environment checks failed or have warnings"
        if [[ "$AUTO_FIX" != true ]]; then
            log_info "Run with --fix to attempt automatic fixes"
        fi
        log_info "Review the issues above and address them before building"
    fi
    
    exit $overall_result
}

# Execute main function
main "$@"