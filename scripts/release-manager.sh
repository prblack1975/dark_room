#!/bin/bash
# GitHub CLI integration for releases and asset management
# Usage: ./release-manager.sh [command] [options]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_OUTPUT_DIR="$PROJECT_DIR/dist"

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

log_release() {
    echo -e "${PURPLE}[RELEASE]${NC} $1"
}

log_upload() {
    echo -e "${CYAN}[UPLOAD]${NC} $1"
}

# Show help
show_help() {
    cat << EOF
Dark Room Game - Release Manager (GitHub CLI Integration)

Usage: $0 <command> [options]

Commands:
  create-release [options]         Create a new GitHub release
    --version=VERSION                Version for the release (auto-detected if not specified)
    --prerelease                     Mark as pre-release
    --draft                          Create as draft release
    --generate-notes                 Auto-generate release notes from commits
    --title=TITLE                    Custom release title
    --notes=FILE                     Release notes from file
    --assets=PATTERN                 Pattern for assets to upload (default: dist/**)
    
  upload-assets <tag> [pattern]    Upload assets to existing release
    
  list-releases                    List all releases
  
  delete-release <tag>             Delete a release
  
  download-assets <tag> [dir]      Download release assets
  
  latest-release                   Show latest release information

Prerequisites:
  - GitHub CLI (gh) must be installed and authenticated
  - Repository must have a GitHub remote origin
  - Proper permissions to create releases

Examples:
  $0 create-release                            # Create release with current version
  $0 create-release --version=1.2.3 --draft   # Create draft release for v1.2.3
  $0 upload-assets v1.2.3 "dist/**/*.zip"     # Upload specific assets
  $0 list-releases                             # Show all releases
  $0 latest-release                            # Show latest release info

EOF
}

# Check prerequisites
check_prerequisites() {
    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        log_info "Install from: https://cli.github.com/"
        exit 1
    fi
    
    # Check if GitHub CLI is authenticated
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated"
        log_info "Run: gh auth login"
        exit 1
    fi
    
    # Check if we're in a git repository with GitHub remote
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
    
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ ! "$remote_url" =~ github\.com ]]; then
        log_error "Repository does not have a GitHub remote origin"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
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

# Generate release notes
generate_release_notes() {
    local version=$1
    local last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    # Generate changelog
    local changelog=""
    if [[ -n "$last_tag" ]]; then
        changelog=$(git log "$last_tag"..HEAD --pretty=format:"- %s (%h)" --reverse)
    else
        changelog=$(git log --pretty=format:"- %s (%h)" --reverse)
    fi
    
    # Create release notes
    cat << EOF
## Dark Room Game Release $version

### 🎮 About Dark Room Game
Dark Room is an audio-based adventure game built with Flutter and Flame. Navigate through dark environments using only spatial audio cues to find objects and solve puzzles.

### 📱 Platform Downloads
- **Android APK**: For Android phones and tablets (enable "Install from unknown sources")
- **Android AAB**: For Google Play Store distribution
- **iOS Build**: For iOS devices (requires proper signing for installation)
- **Windows**: For Windows PC (extract and run)
- **macOS**: For Mac computers (extract and run)
- **Linux**: For Linux distributions (extract and run)
- **Web**: Play directly in your browser

### 🔄 Changes in this Release
$changelog

### 📋 Installation Notes

#### Mobile Platforms
- **Android APK**: Download and install directly. You may need to enable "Install from unknown sources" in your device settings.
- **iOS**: This build is unsigned and requires proper signing with your own developer certificate for installation.

#### Desktop Platforms
- **Windows/macOS/Linux**: Extract the archive and run the executable file.
- On macOS, you may need to allow the app in System Preferences > Security & Privacy if you get a security warning.

#### Web Platform
- Visit the game's GitHub Pages site to play directly in your browser.
- Requires a modern browser with Web Audio API support.
- Chrome, Firefox, Safari, and Edge are all supported.

### 🎧 Game Features
- **Spatial Audio Navigation**: Use 3D audio cues to navigate through dark environments
- **Automatic Item Detection**: Items are automatically picked up when you get close enough
- **Progressive Difficulty**: Multiple levels with increasing complexity
- **Accessibility First**: Designed specifically for audio-based gameplay
- **Cross-Platform**: Available on all major platforms

### 🐛 Known Issues
- iOS builds require manual signing for distribution
- Some antivirus software may flag desktop builds (false positive)
- Web version requires modern browser with audio permissions

### 🆘 Support
If you encounter any issues:
1. Check the repository's Issues section
2. Ensure you have the correct platform requirements
3. For web version, make sure audio permissions are enabled

Enjoy playing Dark Room Game! 🎮🔊
EOF
}

# Create GitHub release
create_release() {
    local version=""
    local prerelease=false
    local draft=false
    local generate_notes=false
    local title=""
    local notes_file=""
    local assets_pattern="$BUILD_OUTPUT_DIR/**"
    
    # Parse options
    for arg in "$@"; do
        case $arg in
            --version=*)
                version="${arg#*=}"
                ;;
            --prerelease)
                prerelease=true
                ;;
            --draft)
                draft=true
                ;;
            --generate-notes)
                generate_notes=true
                ;;
            --title=*)
                title="${arg#*=}"
                ;;
            --notes=*)
                notes_file="${arg#*=}"
                ;;
            --assets=*)
                assets_pattern="${arg#*=}"
                ;;
        esac
    done
    
    # Get version if not specified
    if [[ -z "$version" ]]; then
        version=$(get_current_version)
        log_info "Auto-detected version: $version"
    fi
    
    local tag_name="v$version"
    
    # Check if tag already exists
    if git tag -l | grep -q "^$tag_name$"; then
        log_warning "Tag $tag_name already exists"
    else
        log_info "Creating tag: $tag_name"
        git tag "$tag_name"
        git push origin "$tag_name"
    fi
    
    # Generate title if not provided
    if [[ -z "$title" ]]; then
        title="Dark Room Game v$version"
    fi
    
    # Prepare release notes
    local notes=""
    if [[ -n "$notes_file" && -f "$notes_file" ]]; then
        notes=$(cat "$notes_file")
        log_info "Using release notes from: $notes_file"
    elif [[ "$generate_notes" == true ]]; then
        notes=$(generate_release_notes "$version")
        log_info "Generated release notes from commit history"
    else
        notes=$(generate_release_notes "$version")
        log_info "Using default release notes with changelog"
    fi
    
    # Build release creation command
    local gh_args=()
    gh_args+=("release" "create" "$tag_name")
    gh_args+=("--title" "$title")
    gh_args+=("--notes" "$notes")
    
    if [[ "$prerelease" == true ]]; then
        gh_args+=("--prerelease")
    fi
    
    if [[ "$draft" == true ]]; then
        gh_args+=("--draft")
    fi
    
    # Create release
    log_release "Creating GitHub release: $tag_name"
    
    if gh "${gh_args[@]}"; then
        log_success "Release created successfully: $tag_name"
    else
        log_error "Failed to create release"
        exit 1
    fi
    
    # Upload assets if build artifacts exist
    upload_release_assets "$tag_name" "$assets_pattern"
    
    # Show release URL
    local repo_info=$(gh repo view --json owner,name)
    local owner=$(echo "$repo_info" | jq -r '.owner.login')
    local repo=$(echo "$repo_info" | jq -r '.name')
    local release_url="https://github.com/$owner/$repo/releases/tag/$tag_name"
    
    log_success "Release available at: $release_url"
}

# Upload assets to release
upload_release_assets() {
    local tag_name=$1
    local pattern=${2:-"$BUILD_OUTPUT_DIR/**"}
    
    log_upload "Looking for assets to upload with pattern: $pattern"
    
    # Find all asset files
    local assets=()
    while IFS= read -r -d '' file; do
        # Skip directories and hidden files
        if [[ -f "$file" && "$(basename "$file")" != .* ]]; then
            assets+=("$file")
        fi
    done < <(find "$BUILD_OUTPUT_DIR" -type f -print0 2>/dev/null || true)
    
    if [[ ${#assets[@]} -eq 0 ]]; then
        log_warning "No assets found to upload"
        return 0
    fi
    
    log_info "Found ${#assets[@]} assets to upload"
    
    # Upload each asset
    for asset in "${assets[@]}"; do
        local asset_name=$(basename "$asset")
        local asset_size=$(du -h "$asset" | cut -f1)
        
        log_upload "Uploading $asset_name ($asset_size)..."
        
        if gh release upload "$tag_name" "$asset" --clobber; then
            log_success "✓ Uploaded: $asset_name"
        else
            log_error "✗ Failed to upload: $asset_name"
        fi
    done
    
    log_success "Asset upload completed"
}

# Upload assets to existing release
upload_assets() {
    local tag_name=$1
    local pattern=${2:-"$BUILD_OUTPUT_DIR/**"}
    
    if [[ -z "$tag_name" ]]; then
        log_error "Tag name is required for uploading assets"
        exit 1
    fi
    
    # Check if release exists
    if ! gh release view "$tag_name" > /dev/null 2>&1; then
        log_error "Release $tag_name does not exist"
        exit 1
    fi
    
    upload_release_assets "$tag_name" "$pattern"
}

# List all releases
list_releases() {
    log_info "GitHub Releases:"
    echo
    
    gh release list --limit 20
}

# Delete a release
delete_release() {
    local tag_name=$1
    
    if [[ -z "$tag_name" ]]; then
        log_error "Tag name is required for deleting release"
        exit 1
    fi
    
    # Confirm deletion
    log_warning "This will delete release $tag_name and all its assets"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deletion cancelled"
        exit 0
    fi
    
    # Delete release
    if gh release delete "$tag_name" --yes; then
        log_success "Release $tag_name deleted successfully"
        
        # Ask about deleting the tag
        read -p "Also delete the git tag? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag -d "$tag_name" 2>/dev/null || true
            git push --delete origin "$tag_name" 2>/dev/null || true
            log_success "Git tag $tag_name deleted"
        fi
    else
        log_error "Failed to delete release"
        exit 1
    fi
}

# Download release assets
download_assets() {
    local tag_name=$1
    local download_dir=${2:-"./downloads"}
    
    if [[ -z "$tag_name" ]]; then
        log_error "Tag name is required for downloading assets"
        exit 1
    fi
    
    # Create download directory
    mkdir -p "$download_dir"
    
    log_info "Downloading assets from release $tag_name to $download_dir"
    
    # Download all assets
    gh release download "$tag_name" --dir "$download_dir"
    
    log_success "Assets downloaded to: $download_dir"
}

# Show latest release
show_latest_release() {
    log_info "Latest GitHub Release:"
    echo
    
    gh release view --json tagName,name,publishedAt,assets,body | jq -r '
        "Tag: " + .tagName,
        "Name: " + .name,
        "Published: " + .publishedAt,
        "Assets: " + (.assets | length | tostring),
        "",
        "Description:",
        .body,
        "",
        "Assets:",
        (.assets[] | "- " + .name + " (" + (.size | tostring) + " bytes)")
    '
}

# Build all platforms before release
build_for_release() {
    log_info "Building all platforms for release..."
    
    # Check if build-all script exists
    local build_script="$SCRIPT_DIR/build-all.sh"
    if [[ ! -f "$build_script" ]]; then
        log_error "Build script not found: $build_script"
        exit 1
    fi
    
    # Execute build
    if "$build_script" --build-type=release --clean; then
        log_success "All platforms built successfully"
    else
        log_error "Build failed - cannot proceed with release"
        exit 1
    fi
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
    
    # Check prerequisites for most commands
    case "$command" in
        "help"|"--help"|"-h")
            show_help
            exit 0
            ;;
        *)
            check_prerequisites
            ;;
    esac
    
    case "$command" in
        "create-release")
            # Offer to build first
            read -p "Build all platforms before creating release? (Y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                build_for_release
            fi
            create_release "$@"
            ;;
        "upload-assets")
            upload_assets "$@"
            ;;
        "list-releases")
            list_releases
            ;;
        "delete-release")
            delete_release "$@"
            ;;
        "download-assets")
            download_assets "$@"
            ;;
        "latest-release")
            show_latest_release
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