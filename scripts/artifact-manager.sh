#!/bin/bash
# Multi-platform artifact organization and naming script
# Usage: ./artifact-manager.sh [command] [options]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$PROJECT_DIR/dist"
ARCHIVE_DIR="$PROJECT_DIR/archives"

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
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_organize() {
    echo -e "${PURPLE}[ORGANIZE]${NC} $1"
}

log_archive() {
    echo -e "${CYAN}[ARCHIVE]${NC} $1"
}

# Show help
show_help() {
    cat << EOF
Dark Room Game - Artifact Manager

Usage: $0 <command> [options]

Commands:
  organize [options]               Organize build artifacts with consistent naming
    --version=VERSION                Version for naming (auto-detected if not specified)
    --build-type=TYPE                Build type: debug or release (default: release)
    --clean-first                    Clean existing organized artifacts first
    
  archive [options]                Create deployment-ready archives
    --format=FORMAT                  Archive format: zip, tar.gz, or both (default: both)
    --include-source                 Include source code in archive
    --separate-platforms             Create separate archives per platform
    
  list                            List all current artifacts
  
  clean                           Clean up old artifacts and temporary files
  
  verify                          Verify artifact integrity and completeness
  
  upload-prep [service]           Prepare artifacts for upload to specific service
    github                          Prepare for GitHub Releases
    itch                           Prepare for itch.io
    steam                          Prepare for Steam
    stores                         Prepare for app stores (Google Play, App Store)

Artifact Naming Convention:
  dark_room-v{VERSION}-{PLATFORM}-{BUILD_TYPE}.{EXTENSION}
  
  Examples:
    dark_room-v1.2.3-android-release.apk
    dark_room-v1.2.3-windows-release.zip
    dark_room-v1.2.3-web-release.tar.gz

Directory Structure:
  dist/
  ├── android/          # Android builds (APK, AAB)
  ├── ios/              # iOS builds
  ├── web/              # Web builds
  ├── windows/          # Windows builds
  ├── macos/            # macOS builds
  ├── linux/            # Linux builds
  └── organized/        # Renamed and organized artifacts
      ├── mobile/       # Mobile platforms
      ├── desktop/      # Desktop platforms
      ├── web/          # Web platform
      └── all/          # All platforms combined

Examples:
  $0 organize                                    # Organize with current version
  $0 organize --version=1.2.3 --clean-first     # Clean and organize specific version
  $0 archive --separate-platforms                # Create per-platform archives
  $0 upload-prep github                          # Prepare for GitHub Releases
  $0 verify                                      # Verify all artifacts

EOF
}

# Get current version
get_current_version() {
    local pubspec_file="$PROJECT_DIR/pubspec.yaml"
    
    if [[ ! -f "$pubspec_file" ]]; then
        log_error "pubspec.yaml not found"
        exit 1
    fi
    
    local version_line=$(grep "^version:" "$pubspec_file")
    if [[ -z "$version_line" ]]; then
        log_error "No version found in pubspec.yaml"
        exit 1
    fi
    
    # Extract version part (without build number)
    local full_version=$(echo "$version_line" | sed 's/version: //' | tr -d ' ')
    echo "$full_version" | cut -d'+' -f1
}

# Get file size in human readable format
get_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        du -h "$file" | cut -f1
    else
        echo "0B"
    fi
}

# Generate artifact info
generate_artifact_info() {
    local file="$1"
    local platform="$2"
    local build_type="$3"
    local version="$4"
    
    local size=$(get_file_size "$file")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local checksum=""
    
    if command -v sha256sum &> /dev/null; then
        checksum=$(sha256sum "$file" | cut -d' ' -f1)
    elif command -v shasum &> /dev/null; then
        checksum=$(shasum -a 256 "$file" | cut -d' ' -f1)
    fi
    
    cat << EOF
{
  "filename": "$(basename "$file")",
  "platform": "$platform",
  "buildType": "$build_type",
  "version": "$version",
  "size": "$size",
  "sizeBytes": $(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0),
  "checksum": "$checksum",
  "timestamp": "$timestamp",
  "path": "$file"
}
EOF
}

# Organize artifacts with consistent naming
organize_artifacts() {
    local version=""
    local build_type="release"
    local clean_first=false
    
    # Parse options
    for arg in "$@"; do
        case $arg in
            --version=*)
                version="${arg#*=}"
                ;;
            --build-type=*)
                build_type="${arg#*=}"
                ;;
            --clean-first)
                clean_first=true
                ;;
        esac
    done
    
    # Get version if not specified
    if [[ -z "$version" ]]; then
        version=$(get_current_version)
        log_info "Using current version: $version"
    fi
    
    local organized_dir="$DIST_DIR/organized"
    
    # Clean if requested
    if [[ "$clean_first" == true ]]; then
        log_organize "Cleaning existing organized artifacts..."
        rm -rf "$organized_dir"
    fi
    
    # Create organized directory structure
    mkdir -p "$organized_dir"/{mobile,desktop,web,all}
    
    log_organize "Organizing artifacts for version $version ($build_type)..."
    
    # Track organized files for summary
    declare -a organized_files
    
    # Android artifacts
    if [[ -d "$DIST_DIR/android" ]]; then
        log_info "Processing Android artifacts..."
        
        # APK files
        for apk in "$DIST_DIR/android"/*.apk; do
            if [[ -f "$apk" ]]; then
                local new_name="dark_room-v${version}-android-${build_type}.apk"
                cp "$apk" "$organized_dir/mobile/$new_name"
                cp "$apk" "$organized_dir/all/$new_name"
                organized_files+=("mobile/$new_name")
                log_success "✓ Organized: $new_name"
            fi
        done
        
        # AAB files
        for aab in "$DIST_DIR/android"/*.aab; do
            if [[ -f "$aab" ]]; then
                local new_name="dark_room-v${version}-android-${build_type}.aab"
                cp "$aab" "$organized_dir/mobile/$new_name"
                cp "$aab" "$organized_dir/all/$new_name"
                organized_files+=("mobile/$new_name")
                log_success "✓ Organized: $new_name"
            fi
        done
    fi
    
    # iOS artifacts
    if [[ -d "$DIST_DIR/ios" ]]; then
        log_info "Processing iOS artifacts..."
        
        for ios_archive in "$DIST_DIR/ios"/*.tar.gz; do
            if [[ -f "$ios_archive" ]]; then
                local new_name="dark_room-v${version}-ios-${build_type}.tar.gz"
                cp "$ios_archive" "$organized_dir/mobile/$new_name"
                cp "$ios_archive" "$organized_dir/all/$new_name"
                organized_files+=("mobile/$new_name")
                log_success "✓ Organized: $new_name"
            fi
        done
    fi
    
    # Web artifacts
    if [[ -d "$DIST_DIR/web" ]]; then
        log_info "Processing Web artifacts..."
        
        # Create web archive if it doesn't exist
        local web_archive="$DIST_DIR/dark_room-web-${build_type}.tar.gz"
        if [[ ! -f "$web_archive" ]]; then
            cd "$DIST_DIR/web"
            tar -czf "../dark_room-web-${build_type}.tar.gz" *
            cd "$PROJECT_DIR"
        fi
        
        if [[ -f "$web_archive" ]]; then
            local new_name="dark_room-v${version}-web-${build_type}.tar.gz"
            cp "$web_archive" "$organized_dir/web/$new_name"
            cp "$web_archive" "$organized_dir/all/$new_name"
            organized_files+=("web/$new_name")
            log_success "✓ Organized: $new_name"
        fi
    fi
    
    # Desktop artifacts
    for platform in windows macos linux; do
        if [[ -d "$DIST_DIR/desktop/$platform" ]]; then
            log_info "Processing $platform artifacts..."
            
            for archive in "$DIST_DIR/desktop/$platform"/*.{tar.gz,zip}; do
                if [[ -f "$archive" ]]; then
                    local ext="${archive##*.}"
                    if [[ "$ext" == "gz" ]]; then ext="tar.gz"; fi
                    
                    local new_name="dark_room-v${version}-${platform}-${build_type}.${ext}"
                    cp "$archive" "$organized_dir/desktop/$new_name"
                    cp "$archive" "$organized_dir/all/$new_name"
                    organized_files+=("desktop/$new_name")
                    log_success "✓ Organized: $new_name"
                fi
            done
        fi
    done
    
    # Generate artifact manifest
    local manifest_file="$organized_dir/artifacts-manifest.json"
    local manifest_content='{"version": "'$version'", "buildType": "'$build_type'", "artifacts": ['
    local first=true
    
    for category in mobile desktop web; do
        for file in "$organized_dir/$category"/*; do
            if [[ -f "$file" && "$(basename "$file")" != "artifacts-manifest.json" ]]; then
                if [[ "$first" != true ]]; then
                    manifest_content+=","
                fi
                local platform=""
                case "$category" in
                    "mobile") 
                        if [[ "$file" =~ android ]]; then platform="android"
                        elif [[ "$file" =~ ios ]]; then platform="ios"; fi
                        ;;
                    "desktop")
                        if [[ "$file" =~ windows ]]; then platform="windows"
                        elif [[ "$file" =~ macos ]]; then platform="macos"
                        elif [[ "$file" =~ linux ]]; then platform="linux"; fi
                        ;;
                    "web") platform="web" ;;
                esac
                
                local artifact_info=$(generate_artifact_info "$file" "$platform" "$build_type" "$version")
                manifest_content+="$artifact_info"
                first=false
            fi
        done
    done
    
    manifest_content+="]}"
    echo "$manifest_content" | jq . > "$manifest_file"
    
    # Summary
    log_success "Organization completed! Summary:"
    log_info "Total artifacts organized: ${#organized_files[@]}"
    log_info "Organized directory: $organized_dir"
    log_info "Artifact manifest: $manifest_file"
    
    # Show organized files
    echo
    log_info "Organized artifacts:"
    for file in "${organized_files[@]}"; do
        local full_path="$organized_dir/$file"
        local size=$(get_file_size "$full_path")
        echo "  $file ($size)"
    done
}

# Create deployment archives
create_archives() {
    local format="both"
    local include_source=false
    local separate_platforms=false
    
    # Parse options
    for arg in "$@"; do
        case $arg in
            --format=*)
                format="${arg#*=}"
                ;;
            --include-source)
                include_source=true
                ;;
            --separate-platforms)
                separate_platforms=true
                ;;
        esac
    done
    
    local version=$(get_current_version)
    mkdir -p "$ARCHIVE_DIR"
    
    log_archive "Creating deployment archives..."
    
    if [[ "$separate_platforms" == true ]]; then
        # Create separate archives per platform
        for category in mobile desktop web; do
            local category_dir="$DIST_DIR/organized/$category"
            if [[ -d "$category_dir" ]] && [[ -n "$(ls -A "$category_dir" 2>/dev/null)" ]]; then
                log_info "Creating $category archive..."
                
                local archive_name="dark_room-v${version}-${category}"
                
                case "$format" in
                    "zip"|"both")
                        cd "$category_dir"
                        zip -r "$ARCHIVE_DIR/${archive_name}.zip" *
                        cd "$PROJECT_DIR"
                        log_success "✓ Created: ${archive_name}.zip"
                        ;;
                esac
                
                case "$format" in
                    "tar.gz"|"both")
                        cd "$category_dir"
                        tar -czf "$ARCHIVE_DIR/${archive_name}.tar.gz" *
                        cd "$PROJECT_DIR"
                        log_success "✓ Created: ${archive_name}.tar.gz"
                        ;;
                esac
            fi
        done
    else
        # Create single archive with all platforms
        local all_dir="$DIST_DIR/organized/all"
        if [[ -d "$all_dir" ]] && [[ -n "$(ls -A "$all_dir" 2>/dev/null)" ]]; then
            local archive_name="dark_room-v${version}-all-platforms"
            
            case "$format" in
                "zip"|"both")
                    cd "$all_dir"
                    zip -r "$ARCHIVE_DIR/${archive_name}.zip" *
                    cd "$PROJECT_DIR"
                    log_success "✓ Created: ${archive_name}.zip"
                    ;;
            esac
            
            case "$format" in
                "tar.gz"|"both")
                    cd "$all_dir"
                    tar -czf "$ARCHIVE_DIR/${archive_name}.tar.gz" *
                    cd "$PROJECT_DIR"
                    log_success "✓ Created: ${archive_name}.tar.gz"
                    ;;
            esac
        fi
    fi
    
    # Include source code if requested
    if [[ "$include_source" == true ]]; then
        log_info "Creating source code archive..."
        local source_archive="dark_room-v${version}-source"
        
        # Create temporary directory for source
        local temp_dir=$(mktemp -d)
        local source_dir="$temp_dir/dark_room-v${version}"
        
        # Copy source files
        mkdir -p "$source_dir"
        
        # Copy important files and directories
        for item in lib assets pubspec.yaml pubspec.lock README.md CHANGELOG.md LICENSE android ios web windows macos linux; do
            if [[ -e "$PROJECT_DIR/$item" ]]; then
                cp -r "$PROJECT_DIR/$item" "$source_dir/"
            fi
        done
        
        # Create archives
        case "$format" in
            "zip"|"both")
                cd "$temp_dir"
                zip -r "$ARCHIVE_DIR/${source_archive}.zip" "dark_room-v${version}"
                cd "$PROJECT_DIR"
                log_success "✓ Created: ${source_archive}.zip"
                ;;
        esac
        
        case "$format" in
            "tar.gz"|"both")
                cd "$temp_dir"
                tar -czf "$ARCHIVE_DIR/${source_archive}.tar.gz" "dark_room-v${version}"
                cd "$PROJECT_DIR"
                log_success "✓ Created: ${source_archive}.tar.gz"
                ;;
        esac
        
        # Cleanup
        rm -rf "$temp_dir"
    fi
    
    log_success "Archive creation completed!"
    log_info "Archives saved to: $ARCHIVE_DIR"
}

# List all artifacts
list_artifacts() {
    log_info "Current build artifacts:"
    echo
    
    # Check each platform directory
    for platform_dir in "$DIST_DIR"/*; do
        if [[ -d "$platform_dir" ]]; then
            local platform=$(basename "$platform_dir")
            
            # Skip organized and logs directories in summary
            if [[ "$platform" == "organized" || "$platform" == "logs" ]]; then
                continue
            fi
            
            echo "📱 $platform:"
            local count=0
            for file in "$platform_dir"/*; do
                if [[ -f "$file" ]]; then
                    local name=$(basename "$file")
                    local size=$(get_file_size "$file")
                    echo "  $name ($size)"
                    ((count++))
                fi
            done
            
            if [[ $count -eq 0 ]]; then
                echo "  (no artifacts)"
            fi
            echo
        fi
    done
    
    # Show organized artifacts if they exist
    if [[ -d "$DIST_DIR/organized" ]]; then
        echo "📦 Organized artifacts:"
        for category in mobile desktop web all; do
            local category_dir="$DIST_DIR/organized/$category"
            if [[ -d "$category_dir" ]] && [[ -n "$(ls -A "$category_dir" 2>/dev/null)" ]]; then
                echo "  $category:"
                for file in "$category_dir"/*; do
                    if [[ -f "$file" ]]; then
                        local name=$(basename "$file")
                        local size=$(get_file_size "$file")
                        echo "    $name ($size)"
                    fi
                done
            fi
        done
        echo
    fi
    
    # Show archives if they exist
    if [[ -d "$ARCHIVE_DIR" ]] && [[ -n "$(ls -A "$ARCHIVE_DIR" 2>/dev/null)" ]]; then
        echo "🗜️ Archives:"
        for archive in "$ARCHIVE_DIR"/*; do
            if [[ -f "$archive" ]]; then
                local name=$(basename "$archive")
                local size=$(get_file_size "$archive")
                echo "  $name ($size)"
            fi
        done
        echo
    fi
}

# Clean up artifacts
clean_artifacts() {
    log_info "Cleaning up old artifacts and temporary files..."
    
    # Ask for confirmation
    read -p "This will remove all build artifacts and archives. Continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled"
        return
    fi
    
    # Clean build directory
    if [[ -d "$DIST_DIR" ]]; then
        rm -rf "$DIST_DIR"
        log_success "Removed dist directory"
    fi
    
    # Clean archives
    if [[ -d "$ARCHIVE_DIR" ]]; then
        rm -rf "$ARCHIVE_DIR"
        log_success "Removed archives directory"
    fi
    
    # Clean Flutter build directory
    if [[ -d "$PROJECT_DIR/build" ]]; then
        rm -rf "$PROJECT_DIR/build"
        log_success "Removed Flutter build directory"
    fi
    
    log_success "Cleanup completed!"
}

# Verify artifact integrity
verify_artifacts() {
    log_info "Verifying artifact integrity..."
    
    local issues=0
    
    # Check if manifest exists
    local manifest_file="$DIST_DIR/organized/artifacts-manifest.json"
    if [[ -f "$manifest_file" ]]; then
        log_success "✓ Artifact manifest found"
        
        # Verify each artifact in manifest
        local artifacts=$(jq -r '.artifacts[] | @base64' "$manifest_file" 2>/dev/null || echo "")
        
        while IFS= read -r artifact_data; do
            if [[ -n "$artifact_data" ]]; then
                local artifact=$(echo "$artifact_data" | base64 -d)
                local filename=$(echo "$artifact" | jq -r '.filename')
                local expected_checksum=$(echo "$artifact" | jq -r '.checksum')
                local path=$(echo "$artifact" | jq -r '.path')
                
                if [[ -f "$path" ]]; then
                    # Verify checksum
                    local actual_checksum=""
                    if command -v sha256sum &> /dev/null; then
                        actual_checksum=$(sha256sum "$path" | cut -d' ' -f1)
                    elif command -v shasum &> /dev/null; then
                        actual_checksum=$(shasum -a 256 "$path" | cut -d' ' -f1)
                    fi
                    
                    if [[ "$actual_checksum" == "$expected_checksum" ]]; then
                        log_success "✓ $filename: integrity verified"
                    else
                        log_error "✗ $filename: checksum mismatch"
                        ((issues++))
                    fi
                else
                    log_error "✗ $filename: file not found at $path"
                    ((issues++))
                fi
            fi
        done <<< "$artifacts"
    else
        log_warning "No artifact manifest found"
        ((issues++))
    fi
    
    # Summary
    if [[ $issues -eq 0 ]]; then
        log_success "All artifacts verified successfully!"
        return 0
    else
        log_error "Found $issues integrity issues"
        return 1
    fi
}

# Prepare artifacts for upload to specific services
prepare_upload() {
    local service=${1:-"github"}
    local version=$(get_current_version)
    local upload_dir="$PROJECT_DIR/upload-$service"
    
    log_info "Preparing artifacts for $service upload..."
    
    rm -rf "$upload_dir"
    mkdir -p "$upload_dir"
    
    case "$service" in
        "github")
            # Copy all organized artifacts
            if [[ -d "$DIST_DIR/organized/all" ]]; then
                cp "$DIST_DIR/organized/all"/* "$upload_dir/" 2>/dev/null || true
            fi
            
            # Create README for GitHub release
            cat > "$upload_dir/README.txt" << EOF
Dark Room Game v$version - Release Assets

Platform Downloads:
- dark_room-v${version}-android-release.apk: Android APK (sideload)
- dark_room-v${version}-android-release.aab: Android App Bundle (Play Store)
- dark_room-v${version}-ios-release.tar.gz: iOS build (requires signing)
- dark_room-v${version}-windows-release.zip: Windows executable
- dark_room-v${version}-macos-release.tar.gz: macOS app bundle
- dark_room-v${version}-linux-release.tar.gz: Linux executable
- dark_room-v${version}-web-release.tar.gz: Web build files

Installation instructions and source code:
https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]//' | sed 's/\.git$//')

EOF
            ;;
            
        "itch")
            # Organize for itch.io (Butler upload)
            mkdir -p "$upload_dir"/{windows,macos,linux,android,web}
            
            # Copy and rename for itch.io conventions
            if [[ -f "$DIST_DIR/organized/all/dark_room-v${version}-windows-release.zip" ]]; then
                cp "$DIST_DIR/organized/all/dark_room-v${version}-windows-release.zip" "$upload_dir/windows/dark-room-windows.zip"
            fi
            
            if [[ -f "$DIST_DIR/organized/all/dark_room-v${version}-macos-release.tar.gz" ]]; then
                cp "$DIST_DIR/organized/all/dark_room-v${version}-macos-release.tar.gz" "$upload_dir/macos/dark-room-macos.tar.gz"
            fi
            
            if [[ -f "$DIST_DIR/organized/all/dark_room-v${version}-linux-release.tar.gz" ]]; then
                cp "$DIST_DIR/organized/all/dark_room-v${version}-linux-release.tar.gz" "$upload_dir/linux/dark-room-linux.tar.gz"
            fi
            
            if [[ -f "$DIST_DIR/organized/all/dark_room-v${version}-android-release.apk" ]]; then
                cp "$DIST_DIR/organized/all/dark_room-v${version}-android-release.apk" "$upload_dir/android/dark-room.apk"
            fi
            
            if [[ -d "$DIST_DIR/web" ]]; then
                cp -r "$DIST_DIR/web"/* "$upload_dir/web/"
            fi
            ;;
            
        "stores")
            # Prepare for app store submissions
            mkdir -p "$upload_dir"/{google-play,app-store}
            
            # Google Play
            if [[ -f "$DIST_DIR/organized/all/dark_room-v${version}-android-release.aab" ]]; then
                cp "$DIST_DIR/organized/all/dark_room-v${version}-android-release.aab" "$upload_dir/google-play/"
            fi
            
            # App Store (iOS would need proper signing)
            if [[ -f "$DIST_DIR/organized/all/dark_room-v${version}-ios-release.tar.gz" ]]; then
                cp "$DIST_DIR/organized/all/dark_room-v${version}-ios-release.tar.gz" "$upload_dir/app-store/"
                echo "Note: iOS build requires proper signing and provisioning for App Store submission" > "$upload_dir/app-store/README.txt"
            fi
            ;;
            
        *)
            log_error "Unknown service: $service"
            exit 1
            ;;
    esac
    
    log_success "Upload preparation completed!"
    log_info "Prepared files in: $upload_dir"
    
    # Show what was prepared
    echo
    log_info "Prepared files:"
    find "$upload_dir" -type f | while read file; do
        local name=$(echo "$file" | sed "s|$upload_dir/||")
        local size=$(get_file_size "$file")
        echo "  $name ($size)"
    done
}

# Main execution
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    local command=$1
    shift
    
    cd "$PROJECT_DIR"
    
    case "$command" in
        "organize")
            organize_artifacts "$@"
            ;;
        "archive")
            create_archives "$@"
            ;;
        "list")
            list_artifacts
            ;;
        "clean")
            clean_artifacts
            ;;
        "verify")
            verify_artifacts
            ;;
        "upload-prep")
            prepare_upload "$@"
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"