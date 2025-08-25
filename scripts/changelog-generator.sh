#!/bin/bash
# Automated changelog generation and release notes
# Usage: ./changelog-generator.sh [command] [options]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CHANGELOG_FILE="$PROJECT_DIR/CHANGELOG.md"

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
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_generate() {
    echo -e "${PURPLE}[GENERATE]${NC} $1"
}

# Show help
show_help() {
    cat << EOF
Dark Room Game - Changelog Generator

Usage: $0 <command> [options]

Commands:
  generate [options]               Generate changelog for current version
    --version=VERSION                Version to generate for (auto-detected if not specified)
    --since=TAG                      Generate changes since specific tag
    --format=FORMAT                  Output format: markdown, json, text (default: markdown)
    --output=FILE                    Output file (default: CHANGELOG.md)
    --template=FILE                  Use custom changelog template
    
  update [version]                 Update existing changelog with new version
  
  release-notes [version]          Generate release notes for GitHub
  
  show [version]                   Show changelog for specific version
  
  validate                         Validate changelog format
  
  init                            Initialize changelog file

Options:
  --include-breaking               Include breaking changes section
  --include-migration              Include migration notes
  --group-by-type                 Group changes by type (feat, fix, docs, etc.)
  --exclude-merge                  Exclude merge commits
  --exclude-deps                   Exclude dependency updates

Examples:
  $0 generate                                     # Generate changelog for current version
  $0 generate --version=1.2.3 --since=v1.2.0    # Generate for specific version range
  $0 release-notes                                # Generate GitHub release notes
  $0 update 1.2.3                               # Update changelog with new version
  $0 show 1.2.0                                 # Show changelog for v1.2.0

Commit Message Conventions:
  feat: New feature
  fix: Bug fix
  docs: Documentation changes
  style: Code style changes
  refactor: Code refactoring
  perf: Performance improvements
  test: Test changes
  chore: Maintenance tasks
  BREAKING CHANGE: Breaking changes

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

# Get latest git tag
get_latest_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo ""
}

# Parse commit message into components
parse_commit() {
    local commit_msg="$1"
    local commit_hash="$2"
    
    # Extract type and description
    local type=""
    local scope=""
    local description=""
    local breaking=""
    
    # Check for conventional commit format: type(scope): description
    if [[ "$commit_msg" =~ ^([a-zA-Z]+)(\([^)]+\))?:(.*)$ ]]; then
        type="${BASH_REMATCH[1]}"
        scope="${BASH_REMATCH[2]}"
        description="${BASH_REMATCH[3]}"
        scope="${scope#(}"  # Remove opening parenthesis
        scope="${scope%)}"  # Remove closing parenthesis
        description="${description# }"  # Remove leading space
    else
        # Fallback: try to guess type from keywords
        case "$commit_msg" in
            *"fix"*|*"Fix"*|*"bug"*|*"Bug"*) type="fix" ;;
            *"feat"*|*"Feat"*|*"feature"*|*"Feature"*|*"add"*|*"Add"*) type="feat" ;;
            *"doc"*|*"Doc"*|*"README"*) type="docs" ;;
            *"test"*|*"Test"*) type="test" ;;
            *"refactor"*|*"Refactor"*) type="refactor" ;;
            *"perf"*|*"Perf"*|*"performance"*|*"Performance"*) type="perf" ;;
            *"style"*|*"Style"*) type="style" ;;
            *"chore"*|*"Chore"*|*"update"*|*"Update"*) type="chore" ;;
            *) type="other" ;;
        esac
        description="$commit_msg"
    fi
    
    # Check for breaking changes
    if [[ "$commit_msg" =~ BREAKING\ CHANGE ]] || [[ "$commit_msg" =~ ^[a-zA-Z]+(\([^)]+\))?!: ]]; then
        breaking="true"
    fi
    
    echo "$type|$scope|$description|$breaking|$commit_hash"
}

# Get commits since tag
get_commits_since() {
    local since_tag="$1"
    local exclude_merge="$2"
    
    local git_args=("--pretty=format:%H|%s" "--reverse")
    
    if [[ "$exclude_merge" == true ]]; then
        git_args+=("--no-merges")
    fi
    
    if [[ -n "$since_tag" ]]; then
        git log "${git_args[@]}" "$since_tag"..HEAD
    else
        git log "${git_args[@]}"
    fi
}

# Generate changelog content
generate_changelog_content() {
    local version="$1"
    local since_tag="$2"
    local group_by_type="$3"
    local exclude_merge="$4"
    local exclude_deps="$5"
    local include_breaking="$6"
    
    log_generate "Analyzing commits since $since_tag..."
    
    # Get commits
    local commits=$(get_commits_since "$since_tag" "$exclude_merge")
    
    if [[ -z "$commits" ]]; then
        log_warning "No commits found since $since_tag"
        return
    fi
    
    # Parse commits and categorize
    declare -A commit_types
    declare -a breaking_changes
    declare -a all_changes
    
    while IFS= read -r line; do
        if [[ -z "$line" ]]; then continue; fi
        
        local hash=$(echo "$line" | cut -d'|' -f1)
        local msg=$(echo "$line" | cut -d'|' -f2-)
        
        # Skip dependency updates if requested
        if [[ "$exclude_deps" == true ]] && [[ "$msg" =~ (bump|update|upgrade).*depend ]]; then
            continue
        fi
        
        local parsed=$(parse_commit "$msg" "${hash:0:8}")
        local type=$(echo "$parsed" | cut -d'|' -f1)
        local scope=$(echo "$parsed" | cut -d'|' -f2)
        local description=$(echo "$parsed" | cut -d'|' -f3)
        local breaking=$(echo "$parsed" | cut -d'|' -f4)
        local commit_short=$(echo "$parsed" | cut -d'|' -f5)
        
        # Format the change entry
        local change_entry="- $description"
        if [[ -n "$scope" ]]; then
            change_entry="- **$scope**: $description"
        fi
        change_entry="$change_entry ([${commit_short}](https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]//' | sed 's/\.git$//')/commit/$hash))"
        
        # Add to appropriate category
        if [[ "$breaking" == "true" ]]; then
            breaking_changes+=("$change_entry")
        fi
        
        if [[ "$group_by_type" == true ]]; then
            if [[ -z "${commit_types[$type]}" ]]; then
                commit_types[$type]=""
            fi
            commit_types[$type]="${commit_types[$type]}$change_entry"$'\n'
        else
            all_changes+=("$change_entry")
        fi
        
    done <<< "$commits"
    
    # Generate output
    local changelog_content=""
    local date=$(date +"%Y-%m-%d")
    
    changelog_content+="## [$version] - $date"$'\n\n'
    
    # Breaking changes first
    if [[ "$include_breaking" == true ]] && [[ ${#breaking_changes[@]} -gt 0 ]]; then
        changelog_content+="### ⚠️ BREAKING CHANGES"$'\n\n'
        for change in "${breaking_changes[@]}"; do
            changelog_content+="$change"$'\n'
        done
        changelog_content+=$'\n'
    fi
    
    # Grouped by type
    if [[ "$group_by_type" == true ]]; then
        # Define order and labels for commit types
        declare -A type_labels
        type_labels[feat]="✨ Features"
        type_labels[fix]="🐛 Bug Fixes"
        type_labels[perf]="⚡ Performance Improvements"
        type_labels[refactor]="♻️ Code Refactoring"
        type_labels[docs]="📚 Documentation"
        type_labels[style]="💄 Styles"
        type_labels[test]="✅ Tests"
        type_labels[chore]="🔧 Chores"
        type_labels[other]="📦 Other Changes"
        
        local type_order=("feat" "fix" "perf" "refactor" "docs" "style" "test" "chore" "other")
        
        for type in "${type_order[@]}"; do
            if [[ -n "${commit_types[$type]}" ]]; then
                changelog_content+="### ${type_labels[$type]}"$'\n\n'
                changelog_content+="${commit_types[$type]}"$'\n'
            fi
        done
    else
        # All changes in chronological order
        if [[ ${#all_changes[@]} -gt 0 ]]; then
            changelog_content+="### Changes"$'\n\n'
            for change in "${all_changes[@]}"; do
                changelog_content+="$change"$'\n'
            done
            changelog_content+=$'\n'
        fi
    fi
    
    echo "$changelog_content"
}

# Generate full changelog
generate_changelog() {
    local version=""
    local since_tag=""
    local output_format="markdown"
    local output_file="$CHANGELOG_FILE"
    local template_file=""
    local group_by_type=true
    local exclude_merge=true
    local exclude_deps=true
    local include_breaking=true
    
    # Parse options
    for arg in "$@"; do
        case $arg in
            --version=*)
                version="${arg#*=}"
                ;;
            --since=*)
                since_tag="${arg#*=}"
                ;;
            --format=*)
                output_format="${arg#*=}"
                ;;
            --output=*)
                output_file="${arg#*=}"
                ;;
            --template=*)
                template_file="${arg#*=}"
                ;;
            --group-by-type)
                group_by_type=true
                ;;
            --exclude-merge)
                exclude_merge=true
                ;;
            --exclude-deps)
                exclude_deps=true
                ;;
            --include-breaking)
                include_breaking=true
                ;;
        esac
    done
    
    # Get version if not specified
    if [[ -z "$version" ]]; then
        version=$(get_current_version)
        log_info "Using current version: $version"
    fi
    
    # Get since tag if not specified
    if [[ -z "$since_tag" ]]; then
        since_tag=$(get_latest_tag)
        if [[ -n "$since_tag" ]]; then
            log_info "Generating changes since: $since_tag"
        else
            log_info "No previous tags found, generating full history"
        fi
    fi
    
    # Generate changelog content
    local content=$(generate_changelog_content "$version" "$since_tag" "$group_by_type" "$exclude_merge" "$exclude_deps" "$include_breaking")
    
    if [[ -z "$content" ]]; then
        log_warning "No changelog content generated"
        return
    fi
    
    # Output based on format
    case "$output_format" in
        "markdown")
            # Create or update markdown changelog
            local temp_file=$(mktemp)
            
            # Write header if creating new file
            if [[ ! -f "$output_file" ]]; then
                cat > "$temp_file" << EOF
# Changelog

All notable changes to the Dark Room game will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

EOF
            else
                # Read existing file until first version entry
                awk '/^## \[/ {exit} {print}' "$output_file" > "$temp_file"
            fi
            
            # Add new content
            echo "$content" >> "$temp_file"
            
            # Add existing changelog content if file exists
            if [[ -f "$output_file" ]]; then
                awk '/^## \[/ {print} found {print} /^## \[/ {found=1}' "$output_file" >> "$temp_file"
            fi
            
            mv "$temp_file" "$output_file"
            log_success "Changelog updated: $output_file"
            ;;
            
        "json")
            # Generate JSON format
            local json_content=$(echo "$content" | jq -Rs '{
                "version": "'$version'",
                "date": "'$(date +"%Y-%m-%d")'",
                "content": .
            }')
            echo "$json_content" > "$output_file"
            log_success "JSON changelog generated: $output_file"
            ;;
            
        "text")
            # Generate plain text format
            echo "$content" > "$output_file"
            log_success "Text changelog generated: $output_file"
            ;;
            
        *)
            log_error "Unsupported format: $output_format"
            exit 1
            ;;
    esac
}

# Generate release notes for GitHub
generate_release_notes() {
    local version=${1:-$(get_current_version)}
    local since_tag=$(get_latest_tag)
    
    log_generate "Generating GitHub release notes for version $version..."
    
    # Get changelog content
    local content=$(generate_changelog_content "$version" "$since_tag" true true true true)
    
    # Create release notes with additional context
    cat << EOF
## 🎮 Dark Room Game v$version

Dark Room is an immersive audio-based adventure game where you navigate through dark environments using spatial audio cues to find objects and solve puzzles.

### 🎧 Game Features
- **Spatial Audio Navigation**: Use 3D audio positioning to explore environments
- **Automatic Item Detection**: Items are picked up automatically when you get close
- **Progressive Difficulty**: Multiple levels with increasing complexity
- **Cross-Platform**: Available on Web, Android, iOS, Windows, macOS, and Linux
- **Accessibility First**: Designed specifically for audio-based gameplay

$content

### 📱 Platform Downloads
Choose the version for your platform:

- **🌐 Web**: Play directly in your browser (no download required)
- **🤖 Android APK**: For Android devices (enable "Install from unknown sources")
- **🍎 iOS**: For iPhone/iPad (requires signing for installation)
- **🪟 Windows**: Extract ZIP and run executable
- **🍎 macOS**: Extract archive and run app (may need to allow in Security settings)
- **🐧 Linux**: Extract archive and run executable

### 🔧 Installation Notes

#### Web Version
- Visit the game's GitHub Pages site
- Requires modern browser with Web Audio API
- Grant microphone/audio permissions when prompted

#### Mobile Platforms
- **Android**: Download APK and install (may need to enable unknown sources)
- **iOS**: Unsigned build requires developer signing for installation

#### Desktop Platforms
- **Windows/Linux**: Extract archive and run the executable
- **macOS**: Extract archive, may need to right-click → Open to bypass security warnings

### 🐛 Known Issues
- iOS builds require manual code signing
- Some antivirus software may flag executables (false positive)
- Web version needs audio permissions enabled

### 🆘 Support & Feedback
- 🐛 **Report bugs**: [GitHub Issues](https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]//' | sed 's/\.git$//')/issues)
- 💡 **Feature requests**: [GitHub Discussions](https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]//' | sed 's/\.git$//')/discussions)
- 📖 **Documentation**: Check the README for detailed setup instructions

**Enjoy your journey through the Dark Room! 🕯️🎮**
EOF
}

# Update existing changelog
update_changelog() {
    local version=${1:-$(get_current_version)}
    
    log_info "Updating changelog for version $version..."
    
    generate_changelog --version="$version"
}

# Show changelog for specific version
show_changelog() {
    local version=$1
    
    if [[ -z "$version" ]]; then
        log_error "Version is required"
        exit 1
    fi
    
    if [[ ! -f "$CHANGELOG_FILE" ]]; then
        log_error "Changelog file not found: $CHANGELOG_FILE"
        exit 1
    fi
    
    local tag_pattern="^## \\[$version\\]"
    
    # Find and display the version section
    awk "/$tag_pattern/,/^## \\[/ {if (/^## \\[/ && !/$tag_pattern/) exit; print}" "$CHANGELOG_FILE"
}

# Validate changelog format
validate_changelog() {
    if [[ ! -f "$CHANGELOG_FILE" ]]; then
        log_warning "Changelog file not found: $CHANGELOG_FILE"
        return 1
    fi
    
    log_info "Validating changelog format..."
    
    local errors=0
    
    # Check if it follows Keep a Changelog format
    if ! grep -q "^# Changelog" "$CHANGELOG_FILE"; then
        log_warning "Missing main 'Changelog' header"
        ((errors++))
    fi
    
    if ! grep -q "Keep a Changelog" "$CHANGELOG_FILE"; then
        log_warning "Missing reference to Keep a Changelog format"
        ((errors++))
    fi
    
    # Check version format
    if grep -E "^## \[[0-9]+\.[0-9]+\.[0-9]+\]" "$CHANGELOG_FILE" >/dev/null; then
        log_success "Version format is correct"
    else
        log_warning "Version entries may not follow semantic versioning"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "Changelog format validation passed"
        return 0
    else
        log_warning "Changelog format validation found $errors issues"
        return 1
    fi
}

# Initialize changelog file
init_changelog() {
    if [[ -f "$CHANGELOG_FILE" ]]; then
        log_warning "Changelog file already exists: $CHANGELOG_FILE"
        read -p "Overwrite existing file? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Initialization cancelled"
            return
        fi
    fi
    
    cat > "$CHANGELOG_FILE" << EOF
# Changelog

All notable changes to the Dark Room game will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup

EOF
    
    log_success "Changelog initialized: $CHANGELOG_FILE"
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
        "generate")
            generate_changelog "$@"
            ;;
        "update")
            update_changelog "$@"
            ;;
        "release-notes")
            generate_release_notes "$@"
            ;;
        "show")
            show_changelog "$@"
            ;;
        "validate")
            validate_changelog
            ;;
        "init")
            init_changelog
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