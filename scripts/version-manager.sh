#!/bin/bash
# Version management and automated build numbering script
# Usage: ./version-manager.sh [command] [options]
# Commands:
#   current                         Show current version
#   bump [major|minor|patch]        Bump version number
#   set <version>                   Set specific version
#   build-number [increment|set]    Manage build number
#   tag [--push]                    Create git tag for current version

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PUBSPEC_FILE="$PROJECT_DIR/pubspec.yaml"
VERSION_FILE="$PROJECT_DIR/.version"

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

# Show help
show_help() {
    cat << EOF
Dark Room Game - Version Management

Usage: $0 <command> [options]

Commands:
  current                       Show current version information
  bump <type>                   Bump version number
    major                         X.0.0 (breaking changes)
    minor                         x.Y.0 (new features)
    patch                         x.y.Z (bug fixes)
  
  set <version>                 Set specific version (e.g., 1.2.3)
  
  build-number <action>         Manage build number
    increment                     Increment build number by 1
    set <number>                  Set specific build number
    reset                         Reset build number to 1
  
  tag [options]                 Create git tag for current version
    --push                        Push tag to remote repository
    --annotate                    Create annotated tag with changelog
  
  changelog                     Generate changelog since last version

Examples:
  $0 current                    # Show current version
  $0 bump minor                 # Bump from 1.2.3+4 to 1.3.0+5
  $0 set 2.0.0                  # Set version to 2.0.0+1
  $0 build-number increment     # Increment build number
  $0 tag --push                 # Create and push git tag

Version Format:
  Flutter uses semantic versioning: MAJOR.MINOR.PATCH+BUILD
  Example: 1.2.3+45

EOF
}

# Get current version from pubspec.yaml
get_current_version() {
    if [[ ! -f "$PUBSPEC_FILE" ]]; then
        log_error "pubspec.yaml not found at: $PUBSPEC_FILE"
        exit 1
    fi
    
    local version_line=$(grep "^version:" "$PUBSPEC_FILE")
    if [[ -z "$version_line" ]]; then
        log_error "No version found in pubspec.yaml"
        exit 1
    fi
    
    echo "$version_line" | sed 's/version: //' | tr -d ' '
}

# Parse version string into components
parse_version() {
    local version=$1
    
    # Split version and build number
    local version_part=$(echo "$version" | cut -d'+' -f1)
    local build_part=$(echo "$version" | cut -d'+' -f2)
    
    # If no build number, default to 1
    if [[ "$version_part" == "$build_part" ]]; then
        build_part="1"
    fi
    
    # Split version into major.minor.patch
    local major=$(echo "$version_part" | cut -d'.' -f1)
    local minor=$(echo "$version_part" | cut -d'.' -f2)
    local patch=$(echo "$version_part" | cut -d'.' -f3)
    
    echo "$major $minor $patch $build_part"
}

# Update version in pubspec.yaml
update_pubspec_version() {
    local new_version=$1
    
    # Create backup
    cp "$PUBSPEC_FILE" "$PUBSPEC_FILE.bak"
    
    # Update version line
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed syntax
        sed -i '' "s/^version: .*/version: $new_version/" "$PUBSPEC_FILE"
    else
        # Linux sed syntax
        sed -i "s/^version: .*/version: $new_version/" "$PUBSPEC_FILE"
    fi
    
    log_success "Updated pubspec.yaml version to: $new_version"
}

# Save version information to version file
save_version_info() {
    local version=$1
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local commit_hash=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    
    cat > "$VERSION_FILE" << EOF
{
  "version": "$version",
  "timestamp": "$timestamp",
  "commitHash": "$commit_hash",
  "buildMachine": "$(uname -n)",
  "buildUser": "$(whoami)"
}
EOF
    
    log_info "Version information saved to .version file"
}

# Show current version information
show_current_version() {
    local current_version=$(get_current_version)
    local parsed=($(parse_version "$current_version"))
    local major=${parsed[0]}
    local minor=${parsed[1]}
    local patch=${parsed[2]}
    local build=${parsed[3]}
    
    echo "Current Version Information:"
    echo "=========================="
    echo "Full version: $current_version"
    echo "Major:        $major"
    echo "Minor:        $minor"
    echo "Patch:        $patch"
    echo "Build:        $build"
    echo ""
    
    # Show git information if available
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local commit_hash=$(git rev-parse HEAD)
        local commit_date=$(git show -s --format=%ci HEAD)
        local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        
        echo "Git Information:"
        echo "Branch:       $branch"
        echo "Commit:       ${commit_hash:0:8}"
        echo "Date:         $commit_date"
        echo ""
    fi
    
    # Show version file if it exists
    if [[ -f "$VERSION_FILE" ]]; then
        echo "Last Build Information:"
        cat "$VERSION_FILE" | jq -r '. | "Timestamp:    " + .timestamp + "\nBuild User:   " + .buildUser + "\nBuild Machine: " + .buildMachine' 2>/dev/null || cat "$VERSION_FILE"
    fi
}

# Bump version
bump_version() {
    local bump_type=$1
    local current_version=$(get_current_version)
    local parsed=($(parse_version "$current_version"))
    local major=${parsed[0]}
    local minor=${parsed[1]}
    local patch=${parsed[2]}
    local build=${parsed[3]}
    
    case "$bump_type" in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            build=$((build + 1))
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            build=$((build + 1))
            ;;
        "patch")
            patch=$((patch + 1))
            build=$((build + 1))
            ;;
        *)
            log_error "Invalid bump type: $bump_type. Use 'major', 'minor', or 'patch'"
            exit 1
            ;;
    esac
    
    local new_version="$major.$minor.$patch+$build"
    
    log_info "Bumping version: $current_version -> $new_version"
    update_pubspec_version "$new_version"
    save_version_info "$new_version"
    
    log_success "Version bumped successfully!"
}

# Set specific version
set_version() {
    local new_version_part=$1
    
    # Validate version format
    if ! echo "$new_version_part" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        log_error "Invalid version format: $new_version_part. Use format: X.Y.Z"
        exit 1
    fi
    
    # Get current build number or start from 1
    local current_version=$(get_current_version)
    local current_build=1
    
    if echo "$current_version" | grep -q '+'; then
        local parsed=($(parse_version "$current_version"))
        current_build=${parsed[3]}
    fi
    
    local new_version="$new_version_part+$current_build"
    
    log_info "Setting version: $current_version -> $new_version"
    update_pubspec_version "$new_version"
    save_version_info "$new_version"
    
    log_success "Version set successfully!"
}

# Manage build number
manage_build_number() {
    local action=$1
    local value=$2
    
    local current_version=$(get_current_version)
    local parsed=($(parse_version "$current_version"))
    local major=${parsed[0]}
    local minor=${parsed[1]}
    local patch=${parsed[2]}
    local build=${parsed[3]}
    
    case "$action" in
        "increment")
            build=$((build + 1))
            ;;
        "set")
            if [[ -z "$value" ]] || ! [[ "$value" =~ ^[0-9]+$ ]]; then
                log_error "Invalid build number: $value. Must be a positive integer"
                exit 1
            fi
            build=$value
            ;;
        "reset")
            build=1
            ;;
        *)
            log_error "Invalid build number action: $action. Use 'increment', 'set', or 'reset'"
            exit 1
            ;;
    esac
    
    local new_version="$major.$minor.$patch+$build"
    
    log_info "Updating build number: $current_version -> $new_version"
    update_pubspec_version "$new_version"
    save_version_info "$new_version"
    
    log_success "Build number updated successfully!"
}

# Create git tag
create_git_tag() {
    local push_tag=false
    local annotate_tag=false
    
    # Parse options
    for arg in "$@"; do
        case $arg in
            --push)
                push_tag=true
                ;;
            --annotate)
                annotate_tag=true
                ;;
        esac
    done
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
    
    local current_version=$(get_current_version)
    local version_part=$(echo "$current_version" | cut -d'+' -f1)
    local tag_name="v$version_part"
    
    # Check if tag already exists
    if git tag -l | grep -q "^$tag_name$"; then
        log_error "Tag $tag_name already exists"
        exit 1
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        log_warning "You have uncommitted changes"
        read -p "Continue with tagging? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Tagging cancelled"
            exit 0
        fi
    fi
    
    # Create tag
    if [[ "$annotate_tag" == true ]]; then
        # Generate changelog for annotation
        local changelog=$(generate_changelog_since_last_tag)
        local tag_message="Release $tag_name\n\n$changelog"
        
        git tag -a "$tag_name" -m "$tag_message"
        log_success "Created annotated tag: $tag_name"
    else
        git tag "$tag_name"
        log_success "Created tag: $tag_name"
    fi
    
    # Push tag if requested
    if [[ "$push_tag" == true ]]; then
        log_info "Pushing tag to remote repository..."
        git push origin "$tag_name"
        log_success "Tag pushed to remote: $tag_name"
    fi
}

# Generate changelog since last tag
generate_changelog_since_last_tag() {
    local last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [[ -z "$last_tag" ]]; then
        # No previous tags, show all commits
        git log --pretty=format:"- %s (%h)" --reverse
    else
        # Show commits since last tag
        git log "$last_tag"..HEAD --pretty=format:"- %s (%h)" --reverse
    fi
}

# Generate full changelog
generate_changelog() {
    local changelog_file="$PROJECT_DIR/CHANGELOG.md"
    local current_version=$(get_current_version)
    local version_part=$(echo "$current_version" | cut -d'+' -f1)
    local today=$(date +"%Y-%m-%d")
    
    # Create temporary file with new content
    local temp_file=$(mktemp)
    
    # Write header for new version
    cat > "$temp_file" << EOF
# Changelog

All notable changes to the Dark Room game will be documented in this file.

## [${version_part}] - ${today}

$(generate_changelog_since_last_tag)

EOF
    
    # Append existing changelog if it exists
    if [[ -f "$changelog_file" ]]; then
        # Skip the header and first version if they exist
        tail -n +4 "$changelog_file" >> "$temp_file" 2>/dev/null || cat "$changelog_file" >> "$temp_file"
    fi
    
    # Replace the original file
    mv "$temp_file" "$changelog_file"
    
    log_success "Changelog updated: $changelog_file"
}

# Pre-build version increment
pre_build_increment() {
    local build_type=${1:-release}
    
    log_info "Pre-build version increment for $build_type build"
    
    # Only increment build number for release builds
    if [[ "$build_type" == "release" ]]; then
        manage_build_number "increment"
    else
        log_info "Skipping build number increment for debug build"
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
    
    case "$command" in
        "current")
            show_current_version
            ;;
        "bump")
            if [[ $# -eq 0 ]]; then
                log_error "Bump type required. Use 'major', 'minor', or 'patch'"
                exit 1
            fi
            bump_version "$1"
            ;;
        "set")
            if [[ $# -eq 0 ]]; then
                log_error "Version required. Use format: X.Y.Z"
                exit 1
            fi
            set_version "$1"
            ;;
        "build-number")
            if [[ $# -eq 0 ]]; then
                log_error "Build number action required. Use 'increment', 'set', or 'reset'"
                exit 1
            fi
            manage_build_number "$1" "$2"
            ;;
        "tag")
            create_git_tag "$@"
            ;;
        "changelog")
            generate_changelog
            ;;
        "pre-build-increment")
            pre_build_increment "$1"
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